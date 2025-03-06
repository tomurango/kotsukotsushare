const { getFirestore } = require("firebase-admin/firestore");

const db = getFirestore();

async function getMyQuestions(userId) {
  const myQuestionsSnapshot = await db.collection("questions")
    .where("createdBy", "==", userId)
    .get();

  return myQuestionsSnapshot.docs.map(doc => ({
    id: doc.id,
    text: doc.data().text,
  }));
}

module.exports = getMyQuestions;
