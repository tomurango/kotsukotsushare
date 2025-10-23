const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { distributeRewards } = require("../rewards/distributeRewards");

const db = getFirestore();

exports.selectBestAnswer = onCall(async (request) => {
  try {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError("unauthenticated", "ログインが必要です。");
    }

    const { questionId, answerId } = request.data;

    if (!questionId || !answerId) {
      throw new HttpsError("invalid-argument", "questionId と answerId が必要です。");
    }

    // 質問の存在確認と所有者チェック
    const questionRef = db.collection("questions").doc(questionId);
    const questionDoc = await questionRef.get();

    if (!questionDoc.exists) {
      throw new HttpsError("not-found", "質問が見つかりません。");
    }

    const questionData = questionDoc.data();
    const questionOwnerId = questionData.createdBy || questionData.userId;

    if (questionOwnerId !== userId) {
      throw new HttpsError("permission-denied", "この質問の所有者ではありません。");
    }

    // 既にベストアンサーが選択されているかチェック
    if (questionData.bestAnswerId) {
      throw new HttpsError("already-exists", "既にベストアンサーが選択されています。");
    }

    // 回答の存在確認
    const answerRef = questionRef.collection("answers").doc(answerId);
    const answerDoc = await answerRef.get();

    if (!answerDoc.exists) {
      throw new HttpsError("not-found", "回答が見つかりません。");
    }

    const answerData = answerDoc.data();
    const answererId = answerData.userId || answerData.createdBy;

    // トランザクションでベストアンサーを設定
    await db.runTransaction(async (transaction) => {
      // 質問にベストアンサーIDを設定
      transaction.update(questionRef, {
        bestAnswerId: answerId,
        bestAnswerSelectedAt: FieldValue.serverTimestamp(),
      });

      // 回答にベストアンサーフラグを設定
      transaction.update(answerRef, {
        isBestAnswer: true,
        selectedAsBestAt: FieldValue.serverTimestamp(),
      });
    });

    console.log(`Best answer selected: ${answerId} for question ${questionId}`);

    // 貢献度プールから報酬を分配
    let distributionResult = null;
    try {
      distributionResult = await distributeRewards(questionId);
      console.log("Reward distribution result:", distributionResult);
    } catch (error) {
      console.error("Error distributing rewards:", error);
      // 報酬分配エラーは警告として扱い、ベストアンサー選択は成功とする
    }

    return {
      success: true,
      questionId: questionId,
      answerId: answerId,
      answererId: answererId,
      rewardDistribution: distributionResult,
    };
  } catch (error) {
    console.error("Error selecting best answer:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "ベストアンサーの選択に失敗しました。");
  }
});