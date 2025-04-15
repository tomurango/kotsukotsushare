const { getFirestore } = require("firebase-admin/firestore");

const db = getFirestore();

async function getBlockedUsers(userId) {
  if (!userId) {
    throw new Error("unauthenticated", "ログインが必要です。");
  }

  const blockedUsersSnapshot = await db
    .collection("users")
    .doc(userId)
    .collection("blockedUsers")
    .get();
  if (blockedUsersSnapshot.empty) {
    return [];
  }
  return blockedUsersSnapshot.docs.map(doc => doc.id);
}

module.exports = getBlockedUsers;
