const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const db = getFirestore();

// 貢献度ポイントの定義
const BASE_POINTS = 1; // 回答投稿の基本ポイント
const BEST_ANSWER_BONUS = 5; // ベストアンサーボーナスポイント

/**
 * 質問の貢献度プールから報酬を分配
 * @param {string} questionId - 質問ID
 * @returns {Promise<Object>} 分配結果
 */
async function distributeRewards(questionId) {
  try {
    console.log(`Starting reward distribution for question: ${questionId}`);

    // プール情報を取得
    const poolRef = db.collection("contribution_pools").doc(questionId);
    const poolDoc = await poolRef.get();

    if (!poolDoc.exists) {
      console.log("No contribution pool found for this question");
      return { success: false, message: "プールが存在しません" };
    }

    const poolData = poolDoc.data();

    // 既に分配済みの場合はスキップ
    if (poolData.distributed) {
      console.log("Rewards already distributed");
      return { success: false, message: "既に分配済みです" };
    }

    const poolAmount = poolData.pool_amount || 0;

    if (poolAmount === 0) {
      console.log("Pool amount is zero");
      return { success: false, message: "プール金額が0円です" };
    }

    // 質問のすべての回答を取得
    const answersSnapshot = await db.collection("questions")
      .doc(questionId)
      .collection("answers")
      .get();

    if (answersSnapshot.empty) {
      console.log("No answers found for this question");
      return { success: false, message: "回答が存在しません" };
    }

    // 貢献度ポイントを計算
    const contributions = {};
    let totalPoints = 0;

    answersSnapshot.forEach((doc) => {
      const answer = doc.data();
      const answererId = answer.userId || answer.createdBy;

      if (!answererId) {
        console.warn(`Answer ${doc.id} has no user ID`);
        return;
      }

      // 基本ポイント
      let points = BASE_POINTS;

      // ベストアンサーボーナス
      if (answer.isBestAnswer === true) {
        points += BEST_ANSWER_BONUS;
      }

      if (!contributions[answererId]) {
        contributions[answererId] = {
          userId: answererId,
          points: 0,
          answerCount: 0,
          isBestAnswerer: false,
        };
      }

      contributions[answererId].points += points;
      contributions[answererId].answerCount += 1;

      if (answer.isBestAnswer === true) {
        contributions[answererId].isBestAnswerer = true;
      }

      totalPoints += points;
    });

    console.log(`Total points: ${totalPoints}, Pool amount: ${poolAmount}`);

    // 報酬を計算して付与
    const rewards = [];
    const rewardPromises = [];

    for (const [userId, contribution] of Object.entries(contributions)) {
      // 貢献度に応じて報酬を按分
      const rewardAmount = Math.floor((poolAmount * contribution.points) / totalPoints);

      if (rewardAmount > 0) {
        const rewardId = db.collection("answer_rewards").doc().id;
        const rewardData = {
          id: rewardId,
          question_id: questionId,
          answerer_id: userId,
          reward_amount: rewardAmount,
          contribution_points: contribution.points,
          is_best_answerer: contribution.isBestAnswerer,
          status: "pending",
          created_at: FieldValue.serverTimestamp(),
        };

        rewardPromises.push(
          db.collection("answer_rewards").doc(rewardId).set(rewardData)
        );

        rewards.push({
          userId: userId,
          amount: rewardAmount,
          points: contribution.points,
          isBestAnswerer: contribution.isBestAnswerer,
        });

        console.log(`Reward for ${userId}: ${rewardAmount}円 (${contribution.points} points)`);
      }
    }

    // すべての報酬を一括保存
    await Promise.all(rewardPromises);

    // プールを分配済みにマーク
    await poolRef.update({
      distributed: true,
      distributed_at: FieldValue.serverTimestamp(),
      distributed_amount: poolAmount,
      total_points: totalPoints,
    });

    console.log(`Reward distribution completed. Total: ${poolAmount}円 to ${rewards.length} users`);

    return {
      success: true,
      poolAmount: poolAmount,
      totalPoints: totalPoints,
      rewards: rewards,
    };
  } catch (error) {
    console.error("Error distributing rewards:", error);
    throw error;
  }
}

module.exports = { distributeRewards };
