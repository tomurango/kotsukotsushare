// functions/src/blocked/getBlockedQuestions.js

const { onCall } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");

const db = getFirestore();

exports.getBlockedQuestions = onCall(async (request) => {
  const userId = request.auth?.uid;
  if (!userId) throw new Error("unauthenticated");

  // 1. ブロック中のユーザーID一覧を取得
  const blockedSnapshot = await db
    .collection("users")
    .doc(userId)
    .collection("blockedUsers")
    .get();

  const questions = blockedSnapshot.docs.map(doc => ({
    questionId: doc.data().questionId,
    createdAt: doc.data().createdAt?.toDate()?.toISOString() || "",
    text: doc.data().text,
  }));
  if (questions.length === 0) return { questions: [] };

  return { questions };
});
