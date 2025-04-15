const { onCall } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");

const db = getFirestore();

exports.unblockUserByQuestionId = onCall(async (request) => {
  const userId = request.auth?.uid;
  const { questionId } = request.data;

  // log
  console.log("request.data", request.data);
  if (!userId || !questionId) {
    throw new Error("unauthenticated or invalid-argument");
  }
  // debugように
  console.log("userId", userId);
  console.log("questionId", questionId);

  const questionDoc = await db.collection("questions").doc(questionId).get();
  if (!questionDoc.exists) {
    throw new Error("not-found");
  }

  const targetUserId = questionDoc.data().createdBy;

  await db
    .collection("users")
    .doc(userId)
    .collection("blockedUsers")
    .doc(targetUserId)
    .delete();

  return { success: true };
});
