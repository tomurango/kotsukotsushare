const { getFirestore, FieldPath } = require("firebase-admin/firestore");
const getBlockedUsers = require("../utils/getBlockedUsers");

const db = getFirestore();

async function getRandomQuestion(userId) {
  const blockedUsers = await getBlockedUsers(userId);

  const userDoc = await db.collection("users").doc(userId).get();
  if (!userDoc.exists) {
    throw new Error("not-found", "ユーザー情報が見つかりません。");
  }

  const userData = userDoc.data();
  const answeredQuestions = userData?.answeredQuestions || [];
  const favoriteQuestions = userData?.favoriteQuestions || [];

  let excludedQuestions = [...new Set([...answeredQuestions, ...favoriteQuestions])];

  let query = db.collection("questions")
    .where("createdBy", "!=", userId);

  if (blockedUsers.length > 0) {
    query = query.where("createdBy", "not-in", blockedUsers);
  }

  if (excludedQuestions.length > 0) {
    query = query.where(FieldPath.documentId(), "not-in", excludedQuestions);
  }

  // 🔥 ランダムな閾値を作成
  const randomThreshold = Math.random();

  // 🔥 `random` フィールドが `randomThreshold` 以上のデータを取得
  let questionsSnapshot = await query
    .where("random", ">=", randomThreshold)
    .orderBy("random")
    .limit(1)
    .get();

  // 🔥 もし質問がなければ、`random` フィールドが `randomThreshold` 以下のデータを取得
  if (questionsSnapshot.empty) {
    questionsSnapshot = await query
      .where("random", "<", randomThreshold)
      .orderBy("random")
      .limit(1)
      .get();
  }

  if (questionsSnapshot.empty) return null; // 最終的にデータがない場合

  const question = questionsSnapshot.docs[0];

  return {
    id: question.id,
    text: question.data().text,
  };
}

module.exports = getRandomQuestion;
