const functions = require("firebase-functions");
const admin = require("firebase-admin");

exports.getMyQuestions = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  if (!userId) {
    throw new functions.https.HttpsError("unauthenticated", "ログインが必要です。");
  }

  const questionsSnapshot = await admin.firestore()
      .collection("questions")
      .where("createdBy", "==", userId)
      .orderBy("timestamp", "desc")
      .get();

  return questionsSnapshot.docs.map(doc => ({
    id: doc.id,
    text: doc.data().text,
    timestamp: doc.data().timestamp,
  }));
});
