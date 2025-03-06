const { onCallHandler } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");

const db = getFirestore();

module.exports = onCallHandler(async (request) => {
  const userId = request.auth?.uid;
  const targetUserId = request.data.targetUserId;

  if (!userId) {
    throw new Error("unauthenticated", "ログインが必要です。");
  }
  if (!targetUserId) {
    throw new Error("invalid-argument", "ブロック解除するユーザーIDが必要です。");
  }

  const blockRef = db.collection(`users/${userId}/blockedUsers`).doc(targetUserId);

  await blockRef.delete();

  return { success: true };
});
