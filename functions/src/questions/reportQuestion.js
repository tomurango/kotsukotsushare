const { onCall } = require("firebase-functions/v2/https");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

const db = getFirestore();

exports.reportQuestion = onCall(async (request) => {
    const { questionId, reason } = request.data;
    const uid = request.auth?.uid;
  
    if (!uid) {
        throw new functions.https.HttpsError("unauthenticated", "ユーザー認証に失敗しました");
    }
  
    if (!questionId || !reason) {
        throw new functions.https.HttpsError("invalid-argument", "質問IDまたは理由が不足しています");
    }
  
    // Firestore に報告を記録
    await db.collection("reports").add({
      questionId,
      reason,
      reportedBy: uid,
      reportedAt: Timestamp.now(),
    });
  
    return { success: true };
  });
  