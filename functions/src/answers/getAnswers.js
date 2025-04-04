const { onCall } = require("firebase-functions/v2/https");
const { db } = require("../../config");

// 🔥 Cloud Functions 経由で Firestore から回答を取得
exports.getAnswers = onCall(async (request) => {
  const { questionId } = request.data;

  if (!questionId) {
    throw new Error("invalid-argument", "questionId が必要です");
  }

  /*
  // status を "approved" にフィルタリング
  const approvedAnswersSnapshot = await db.collection("questions")
    .doc(questionId)
    .collection("answers")
    .where("status", "==", "approved")
    .orderBy("createdAt", "desc") // 🔥 最新の回答を取得
    .get();

  // デバッグ用に取得したデータをログ出力
  if (approvedAnswersSnapshot.empty) {
    console.log("No matching documents.");
    return { answers: [] };
  }
  console.log(`Found ${approvedAnswersSnapshot.size} answers for questionId: ${questionId}`);
  // 取得した回答をログ出力
  approvedAnswersSnapshot.forEach(doc => {
    console.log(`Answer ID: ${doc.id}, Data: ${JSON.stringify(doc.data())}`);
  });
  */

  // 質問が自分のものであるかどうかを確認
  const questionDoc = await db.collection("questions").doc(questionId).get();
  if (!questionDoc.exists) {
    throw new Error("not-found", "質問が見つかりません");
  }

  const answersRef = db.collection("questions").doc(questionId).collection("answers");

  // 🔹 自分の投稿（status 無視）
  const myAnswersSnapshot = await answersRef
    .where("createdBy", "==", request.auth.uid)
    .get();

  // 自分の質問の場合のみ他人の投稿を取得する
  let othersAnswersSnapshot = null;
  if (questionDoc.data().createdBy == request.auth.uid) {
    othersAnswersSnapshot = await answersRef
      .where("status", "==", "approved")
      .where("createdBy", "!=", request.auth.uid)
      .get();
  }

  // 🔹 マージ（null 対応）
  const mergedAnswers = [
    ...myAnswersSnapshot.docs,
    ...(othersAnswersSnapshot?.docs ?? []),
  ];
  mergedAnswers.sort((a, b) => {
    const aCreatedAt = a.data().createdAt || new Date(0);
    const bCreatedAt = b.data().createdAt || new Date(0);
    return bCreatedAt - aCreatedAt;
  });

  const answers = mergedAnswers.map(doc => ({
    id: doc.id,
    text: doc.data().text,
    isMine: doc.data().createdBy === request.auth.uid,
  }));  

  return { answers };
});
