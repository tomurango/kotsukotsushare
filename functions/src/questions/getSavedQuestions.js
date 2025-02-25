const functions = require("firebase-functions");
const admin = require("firebase-admin");

exports.getSavedQuestions = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  if (!userId) {
    throw new functions.https.HttpsError("unauthenticated", "ログインが必要です。");
  }

  const userDoc = await admin.firestore().collection("users").doc(userId).get();
  const answeredQuestions = userDoc.data()?.answeredQuestions || [];
  const favoriteQuestions = userDoc.data()?.favoriteQuestions || [];

  const savedQuestionIds = [...new Set([...answeredQuestions, ...favoriteQuestions])];

  if (savedQuestionIds.length === 0) return [];

  const questionsSnapshot = await admin.firestore()
      .collection("questions")
      .where(admin.firestore.FieldPath.documentId(), "in", savedQuestionIds)
      .orderBy("timestamp", "desc")
      .get();

  return questionsSnapshot.docs.map(doc => ({
    id: doc.id,
    text: doc.data().text,
    timestamp: doc.data().timestamp,
  }));
});
