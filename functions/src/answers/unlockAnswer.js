const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const db = getFirestore();

// 回答開封料金
const UNLOCK_PRICE = 100; // 100円
const REWARD_PERCENTAGE = 0.6; // 60%が回答者へ

exports.unlockAnswer = onCall(async (request) => {
  try {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError("unauthenticated", "ログインが必要です。");
    }

    const { answerId, questionId } = request.data;
    if (!answerId || !questionId) {
      throw new HttpsError("invalid-argument", "回答IDと質問IDが必要です。");
    }

    // 回答の存在確認
    const answerRef = db.collection("questions").doc(questionId).collection("answers").doc(answerId);
    const answerDoc = await answerRef.get();

    if (!answerDoc.exists) {
      throw new HttpsError("not-found", "回答が見つかりません。");
    }

    const answerData = answerDoc.data();
    const answererId = answerData.userId || answerData.createdBy;

    // 自分の回答は開封不要
    if (answererId === userId) {
      throw new HttpsError("invalid-argument", "自分の回答は開封できません。");
    }

    // 開封済みか確認
    const unlockSnapshot = await db.collection("answer_unlocks")
      .where("answer_id", "==", answerId)
      .where("unlocked_by", "==", userId)
      .limit(1)
      .get();

    if (!unlockSnapshot.empty) {
      throw new HttpsError("already-exists", "この回答は既に開封済みです。");
    }

    // 開封記録を作成
    const unlockId = db.collection("answer_unlocks").doc().id;
    const unlockData = {
      id: unlockId,
      answer_id: answerId,
      question_id: questionId,
      unlocked_by: userId,
      amount: UNLOCK_PRICE,
      created_at: FieldValue.serverTimestamp(),
    };

    await db.collection("answer_unlocks").doc(unlockId).set(unlockData);

    // 回答に開封者を追加
    await answerRef.update({
      unlocked_by: FieldValue.arrayUnion(userId),
    });

    // 回答者に報酬を付与
    const rewardAmount = Math.floor(UNLOCK_PRICE * REWARD_PERCENTAGE);
    const rewardId = db.collection("answer_rewards").doc().id;
    const rewardData = {
      id: rewardId,
      answer_id: answerId,
      answerer_id: answererId,
      unlock_id: unlockId,
      reward_amount: rewardAmount,
      status: "pending",
      created_at: FieldValue.serverTimestamp(),
    };

    await db.collection("answer_rewards").doc(rewardId).set(rewardData);

    console.log(`Answer ${answerId} unlocked by ${userId}, reward ${rewardAmount} to ${answererId}`);

    return {
      success: true,
      unlockId: unlockId,
      rewardAmount: rewardAmount,
    };
  } catch (error) {
    console.error("Error unlocking answer:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "回答の開封に失敗しました。");
  }
});
