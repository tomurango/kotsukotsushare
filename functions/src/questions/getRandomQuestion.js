const functions = require("firebase-functions");
const admin = require("firebase-admin");

exports.getRandomQuestion = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  if (!userId) {
    throw new functions.https.HttpsError("unauthenticated", "ログインが必要です。");
  }

  // Firestore からユーザー情報を取得（ブロックリスト, 回答済み, お気に入り, 自分の質問）
  const userDoc = await admin.firestore().collection("users").doc(userId).get();
  const blockedUsers = userDoc.data()?.blockedUsers || [];
  const answeredQuestions = userDoc.data()?.answeredQuestions || [];
  const favoriteQuestions = userDoc.data()?.favoriteQuestions || [];

  let excludedQuestions = [...new Set([...answeredQuestions, ...favoriteQuestions])];

  let query = admin.firestore().collection("questions");

  // 自分の質問を除外
  query = query.where("createdBy", "!=", userId);

  // ブロックしたユーザーの質問を除外
  if (blockedUsers.length > 0) {
    query = query.where("createdBy", "not-in", blockedUsers);
  }

  // 回答済み & お気に入りの質問を除外
  if (excludedQuestions.length > 0) {
    query = query.where(admin.firestore.FieldPath.documentId(), "not-in", excludedQuestions);
  }

  const questionsSnapshot = await query
      .orderBy("random")
      .limit(1)
      .get();

  if (questionsSnapshot.empty) return null;

  const question = questionsSnapshot.docs[0];

  return {
    id: question.id,
    text: question.data().text,
    timestamp: question.data().timestamp,
  };
});
