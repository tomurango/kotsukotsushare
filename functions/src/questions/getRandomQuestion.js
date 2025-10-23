const { getFirestore, FieldPath } = require("firebase-admin/firestore");
const getBlockedUsers = require("../utils/getBlockedUsers");

const db = getFirestore();

async function getRandomQuestion(userId) {
  const blockedUsers = await getBlockedUsers(userId);

  const userDoc = await db.collection("users").doc(userId).get();
  if (!userDoc.exists) {
    // ユーザードキュメントが存在しない場合は空データとして扱う
    console.log(`User document not found for ${userId}, treating as new user`);
    return null;
  }

  const userData = userDoc.data();
  const answeredQuestions = userData?.answeredQuestions || [];
  const favoriteQuestions = userData?.favoriteQuestions || [];

  const excludedQuestions = [...new Set([...answeredQuestions, ...favoriteQuestions])];

  // Firestore のクエリ制限により、'not-in' を1つだけ使う
  let query = db.collection("questions");

  // ❗ 'not-in' は最大10件まで
  if (excludedQuestions.length > 0) {
    query = query.where(FieldPath.documentId(), "not-in", excludedQuestions.slice(0, 10));
  }

  // 🔥 ランダムな閾値
  const randomThreshold = Math.random();

  // ランダムに質問を取得（上方向）
  let questionsSnapshot = await query
    .where("random", ">=", randomThreshold)
    .orderBy("random")
    .limit(10) // 多めに取ってあとで JS 側でフィルタ
    .get();

  // 質問がなければ下方向へスキャン
  if (questionsSnapshot.empty) {
    questionsSnapshot = await query
      .where("random", "<", randomThreshold)
      .orderBy("random")
      .limit(10)
      .get();
  }

  if (questionsSnapshot.empty) return null;

  // ❗ JavaScript 側でフィルタリング
  const filteredDocs = questionsSnapshot.docs.filter(doc => {
    const createdBy = doc.data().createdBy;
    return createdBy !== userId && !blockedUsers.includes(createdBy);
  });

  if (filteredDocs.length === 0) return null;

  const question = filteredDocs[0];

  return {
    id: question.id,
    text: question.data().text,
  };
}

module.exports = getRandomQuestion;
