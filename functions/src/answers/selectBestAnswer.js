const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const db = getFirestore();

/**
 * 現在の期間を取得（"2025-10"形式）
 */
function getCurrentPeriod() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  return `${year}-${month}`;
}

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

    // 📊 月次貢献度に+5ポイント加算（ベストアンサーボーナス）
    const currentPeriod = getCurrentPeriod();
    const contributionRef = db
      .collection("monthly_contributions")
      .doc(currentPeriod)
      .collection("users")
      .doc(answererId);

    const contributionDoc = await contributionRef.get();

    if (contributionDoc.exists) {
      // 既存の貢献度に+5ポイント
      await contributionRef.update({
        total_points: FieldValue.increment(5), // +5ポイント（ベストアンサーボーナス）
        best_answer_count: FieldValue.increment(1),
        updated_at: FieldValue.serverTimestamp(),
      });
      console.log(`✅ ${answererId} earned 5 bonus points for best answer in ${currentPeriod}`);
    } else {
      // まだ貢献度記録がない場合（通常は回答投稿時に作成されているはず）
      await contributionRef.set({
        user_id: answererId,
        period: currentPeriod,
        total_points: 5, // ベストアンサーのみの場合
        answer_count: 0, // 回答カウントは0（addAnswerで記録されるべき）
        best_answer_count: 1,
        answers: [],
        created_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      });
      console.log(`⚠️ ${answererId} got best answer but no contribution record, created with 5 points`);
    }

    return {
      success: true,
      questionId: questionId,
      answerId: answerId,
      answererId: answererId,
    };
  } catch (error) {
    console.error("Error selecting best answer:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", "ベストアンサーの選択に失敗しました。");
  }
});