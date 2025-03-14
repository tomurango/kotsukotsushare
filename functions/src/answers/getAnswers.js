const { onCall } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");

const db = getFirestore();

// 🔥 Cloud Functions 経由で Firestore から回答を取得
exports.getAnswers = onCall(async (request) => {
  const { questionId } = request.data;

  if (!questionId) {
    throw new Error("invalid-argument", "questionId が必要です");
  }

  const answersSnapshot = await db.collection("questions")
    .doc(questionId)
    .collection("answers")
    .orderBy("timestamp", "desc") // 🔥 最新の回答を取得
    .get();

  const answers = answersSnapshot.docs.map(doc => ({
    id: doc.id,
    text: doc.data().text,
    timestamp: doc.data().timestamp, // 🔥 投稿者情報は除外
  }));

  return { answers };
});
