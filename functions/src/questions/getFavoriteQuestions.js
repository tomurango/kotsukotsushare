const { getFirestore } = require("firebase-admin/firestore");

const db = getFirestore();

async function getFavoriteQuestions(userId) {
  const userDoc = await db.collection("users").doc(userId).get();
  if (!userDoc.exists) {
    throw new Error("not-found", "ユーザー情報が見つかりません。");
  }

  const favoriteQuestions = userDoc.data()?.favoriteQuestions || [];
  
  if (favoriteQuestions.length === 0) return [];

  const questionsSnapshot = await db.collection("questions")
    .where("__name__", "in", favoriteQuestions)
    .get();

  return questionsSnapshot.docs.map(doc => ({
    id: doc.id,
    text: doc.data().text,
  }));
}

module.exports = getFavoriteQuestions;
