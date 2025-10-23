const { getFirestore } = require("firebase-admin/firestore");

const db = getFirestore();

async function getBlockedUsers(userId) {
  if (!userId) {
    // userIdがない場合は空配列を返す
    console.log("No userId provided to getBlockedUsers, returning empty array");
    return [];
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
