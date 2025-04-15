const { onCall } = require("firebase-functions/v2/https");
const { getFirestore } = require("firebase-admin/firestore");
const functions = require("firebase-functions");

const db = getFirestore();

exports.blockUserByQuestionId = onCall(async (request) => {
  try {
    const { questionId } = request.data;
    const userId = request.auth?.uid;

    if (!userId || !questionId) {
        throw new functions.https.HttpsError("invalid-argument", "ユーザー認証か質問IDが不足しています");
    }

    // 🔍 質問情報を取得
    const questionDoc = await db.collection("questions").doc(questionId).get();

    if (!questionDoc.exists) {
        throw new functions.https.HttpsError("not-found", "該当する質問が存在しません");
    }

    const createdBy = questionDoc.data().createdBy;
    if (!createdBy) {
        throw new functions.https.HttpsError("internal", "質問に投稿者情報がありません");
    }

    if (createdBy === userId) {
        throw new functions.https.HttpsError("failed-precondition", "自分自身をブロックすることはできません");
    }

    // 🔒 ブロックリストに追加
    await db
        .collection("users")
        .doc(userId)
        .collection("blockedUsers")
        .doc(createdBy) // ← 投稿者IDをドキュメントIDに
        .set({createdAt: new Date(), text: questionDoc.data().text, questionId: questionId});

    return { message: "ユーザーをブロックしました"};
  } catch (error) {
    console.error("Error blocking user:", error);
    throw new functions.https.HttpsError("internal", "ユーザーブロック中にエラーが発生しました");
  }
});
