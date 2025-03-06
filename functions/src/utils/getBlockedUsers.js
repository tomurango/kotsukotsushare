const { getFirestore } = require("firebase-admin/firestore");

const db = getFirestore();

async function getBlockedUsers(userId) {
  if (!userId) {
    throw new Error("unauthenticated", "ログインが必要です。");
  }

  const blockedUsersSnapshot = await db.collection(`users/${userId}/blockedUsers`).get();
  return blockedUsersSnapshot.docs.map(doc => doc.id);
}

module.exports = getBlockedUsers;
