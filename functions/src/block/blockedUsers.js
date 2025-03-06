const { onCallHandler } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");

const db = getFirestore();

module.exports = onCallHandler(async (request) => {
  const userId = request.auth?.uid;
  const targetUserId = request.data.targetUserId;
  const reason = request.data.reason || "";

  if (!userId) {
    throw new Error("unauthenticated", "ログインが必要です。");
  }
  if (!targetUserId) {
    throw new Error("invalid-argument", "ブロックするユーザーIDが必要です。");
  }

  const blockRef = db.collection(`users/${userId}/blockedUsers`).doc(targetUserId);

  await blockRef.set({
    blockedAt: new Date(),
    reason,
  });

  return { success: true };
});
