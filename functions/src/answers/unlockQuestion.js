const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue} = require("firebase-admin/firestore");

const db = getFirestore();

// 質問開封料金（月次プールモデル）
const UNLOCK_PRICE = 160; // 160円
const POOL_PERCENTAGE = 0.6; // 60%がプールへ
const IS_TEST_PERIOD = true; // テスト期間中フラグ

/**
 * 現在の期間を取得（"2025-10"形式）
 */
function getCurrentPeriod() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  return `${year}-${month}`;
}

exports.unlockQuestion = onCall(async (request) => {
  try {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError("unauthenticated", "ログインが必要です。");
    }

    const { questionId } = request.data;
    if (!questionId) {
      throw new HttpsError("invalid-argument", "質問IDが必要です。");
    }

    // 質問の存在確認
    const questionRef = db.collection("questions").doc(questionId);
    const questionDoc = await questionRef.get();

    if (!questionDoc.exists) {
      throw new HttpsError("not-found", "質問が見つかりません。");
    }

    const questionData = questionDoc.data();
    const questionOwnerId = questionData.createdBy;

    // 他人の質問は開封できない（UI側で既に制限しているが念のため）
    if (questionOwnerId !== userId) {
      throw new HttpsError("invalid-argument", "他人の質問は開封できません。");
    }

    // 開封済みか確認
    const unlockSnapshot = await db.collection("question_unlocks")
      .where("question_id", "==", questionId)
      .where("unlocked_by", "==", userId)
      .limit(1)
      .get();

    if (!unlockSnapshot.empty) {
      throw new HttpsError("already-exists", "この質問は既に開封済みです。");
    }

    // 現在の期間を取得
    const currentPeriod = getCurrentPeriod();

    // 開封記録を作成
    const unlockId = db.collection("question_unlocks").doc().id;
    const unlockData = {
      id: unlockId,
      question_id: questionId,
      unlocked_by: userId,
      amount: UNLOCK_PRICE,
      is_test: IS_TEST_PERIOD, // テスト期間中フラグ
      created_at: FieldValue.serverTimestamp(),
    };

    await db.collection("question_unlocks").doc(unlockId).set(unlockData);

    // 質問に開封者を追加
    await questionRef.update({
      unlocked_by: FieldValue.arrayUnion(userId),
    });

    // プールへの入金額を計算
    const poolAmount = Math.floor(UNLOCK_PRICE * POOL_PERCENTAGE);

    // 月次プールに金額を追加
    const poolRef = db.collection("monthly_pools").doc(currentPeriod);
    const poolDoc = await poolRef.get();

    if (poolDoc.exists) {
      // 既存のプールに追加
      await poolRef.update({
        pool_amount: FieldValue.increment(poolAmount),
        unlock_count: FieldValue.increment(1),
        updated_at: FieldValue.serverTimestamp(),
      });
    } else {
      // 新規プール作成
      await poolRef.set({
        period: currentPeriod,
        pool_amount: poolAmount,
        unlock_count: 1,
        distributed: false,
        distributed_at: null,
        is_test_period: IS_TEST_PERIOD,
        created_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      });
    }

    console.log(`Question ${questionId} unlocked by ${userId}, ${poolAmount}円 added to ${currentPeriod} pool (test: ${IS_TEST_PERIOD})`);

    return {
      success: true,
      unlockId: unlockId,
      poolAmount: poolAmount,
      period: currentPeriod,
      isTest: IS_TEST_PERIOD,
    };
  } catch (error) {
    console.error("Error unlocking question:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "質問の開封に失敗しました。");
  }
});
