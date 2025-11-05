const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const db = getFirestore();

/**
 * 前月の期間を取得（"2025-09"形式）
 */
function getPreviousPeriod() {
  const now = new Date();
  let year = now.getFullYear();
  let month = now.getMonth(); // 0-11

  if (month === 0) {
    // 1月の場合、前月は前年の12月
    year -= 1;
    month = 12;
  }

  return `${year}-${String(month).padStart(2, "0")}`;
}

/**
 * 月次報酬分配処理
 * @param {string} period - 対象期間（"2025-10"形式）
 */
async function distributeRewardsForPeriod(period) {
  console.log(`Starting reward distribution for period: ${period}`);

  // 1. プール情報を取得
  const poolRef = db.collection("monthly_pools").doc(period);
  const poolDoc = await poolRef.get();

  if (!poolDoc.exists) {
    console.log(`No pool found for period ${period}`);
    return { success: false, message: "プールが存在しません" };
  }

  const poolData = poolDoc.data();

  // 既に分配済みの場合はスキップ
  if (poolData.distributed) {
    console.log(`Rewards already distributed for period ${period}`);
    return { success: false, message: "既に分配済みです" };
  }

  const poolAmount = poolData.pool_amount || 0;
  const isTestPeriod = poolData.is_test_period || false;

  if (poolAmount === 0) {
    console.log(`Pool amount is zero for period ${period}`);
    // プールが0円でも分配済みにマーク
    await poolRef.update({
      distributed: true,
      distributed_at: FieldValue.serverTimestamp(),
      distributed_amount: 0,
      total_points: 0,
    });
    return { success: true, message: "プール金額が0円のため分配なし" };
  }

  // 2. 貢献度データを取得
  const contributionsSnapshot = await db
    .collection("monthly_contributions")
    .doc(period)
    .collection("users")
    .get();

  if (contributionsSnapshot.empty) {
    console.log(`No contributions found for period ${period}`);
    await poolRef.update({
      distributed: true,
      distributed_at: FieldValue.serverTimestamp(),
      distributed_amount: 0,
      total_points: 0,
    });
    return { success: true, message: "貢献度データがないため分配なし" };
  }

  // 3. 総ポイント数を計算
  let totalPoints = 0;
  const contributions = [];

  contributionsSnapshot.forEach((doc) => {
    const data = doc.data();
    const points = data.total_points || 0;
    totalPoints += points;
    contributions.push({
      userId: data.user_id,
      points: points,
      answerCount: data.answer_count || 0,
      bestAnswerCount: data.best_answer_count || 0,
    });
  });

  console.log(`Total points: ${totalPoints}, Pool amount: ${poolAmount}円`);

  if (totalPoints === 0) {
    console.log(`Total points is zero for period ${period}`);
    await poolRef.update({
      distributed: true,
      distributed_at: FieldValue.serverTimestamp(),
      distributed_amount: 0,
      total_points: 0,
    });
    return { success: true, message: "総ポイントが0のため分配なし" };
  }

  // 4. 報酬を計算して付与
  const rewards = [];
  const batch = db.batch();

  for (const contribution of contributions) {
    // 貢献度に応じて報酬を按分
    const rewardAmount = Math.floor((poolAmount * contribution.points) / totalPoints);

    if (rewardAmount > 0) {
      const rewardId = db.collection("answer_rewards").doc().id;
      const rewardRef = db.collection("answer_rewards").doc(rewardId);

      const rewardData = {
        id: rewardId,
        period: period,
        user_id: contribution.userId,
        reward_amount: rewardAmount,
        contribution_points: contribution.points,
        is_best_answerer: contribution.bestAnswerCount > 0,
        status: isTestPeriod ? "test" : "pending", // テスト期間中は"test"
        created_at: FieldValue.serverTimestamp(),
        paid_at: null,
      };

      batch.set(rewardRef, rewardData);

      rewards.push({
        userId: contribution.userId,
        amount: rewardAmount,
        points: contribution.points,
        isBestAnswerer: contribution.bestAnswerCount > 0,
      });

      console.log(
        `Reward for ${contribution.userId}: ${rewardAmount}円 (${contribution.points} points)`
      );
    }
  }

  // 5. プールを分配済みにマーク
  batch.update(poolRef, {
    distributed: true,
    distributed_at: FieldValue.serverTimestamp(),
    distributed_amount: poolAmount,
    total_points: totalPoints,
  });

  // 6. バッチコミット
  await batch.commit();

  console.log(
    `Reward distribution completed for ${period}. Total: ${poolAmount}円 to ${rewards.length} users (test: ${isTestPeriod})`
  );

  return {
    success: true,
    period: period,
    poolAmount: poolAmount,
    totalPoints: totalPoints,
    rewardCount: rewards.length,
    isTestPeriod: isTestPeriod,
    rewards: rewards,
  };
}

/**
 * Cloud Scheduler用: 毎月1日00:00に自動実行
 * cron: "0 0 1 * *" (毎月1日00:00 JST)
 */
exports.distributeMonthlyRewardsScheduled = onSchedule(
  {
    schedule: "0 0 1 * *",
    timeZone: "Asia/Tokyo",
    region: "asia-northeast1",
  },
  async (event) => {
    const previousPeriod = getPreviousPeriod();
    console.log(`Scheduled distribution triggered for period: ${previousPeriod}`);

    try {
      const result = await distributeRewardsForPeriod(previousPeriod);
      console.log("Scheduled distribution result:", result);
      return result;
    } catch (error) {
      console.error("Scheduled distribution failed:", error);
      throw error;
    }
  }
);

/**
 * 手動実行用: 指定した期間の報酬分配（テスト・デバッグ用）
 */
exports.distributeMonthlyRewardsManual = onCall(async (request) => {
  try {
    // 管理者権限チェック（オプション）
    // const userId = request.auth?.uid;
    // if (!userId) {
    //   throw new HttpsError("unauthenticated", "ログインが必要です。");
    // }

    const { period } = request.data;

    if (!period) {
      throw new HttpsError("invalid-argument", "期間（period）が必要です。例: 2025-10");
    }

    // 期間フォーマットチェック
    if (!/^\d{4}-\d{2}$/.test(period)) {
      throw new HttpsError("invalid-argument", "期間は YYYY-MM 形式で指定してください");
    }

    console.log(`Manual distribution triggered for period: ${period}`);

    const result = await distributeRewardsForPeriod(period);
    return result;
  } catch (error) {
    console.error("Manual distribution failed:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "報酬分配に失敗しました。");
  }
});
