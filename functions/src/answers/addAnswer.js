const { onCall } = require("firebase-functions/v2/https");
const functions = require("firebase-functions");
const axios = require("axios");
const { db, FieldValue, model, PERSPECTIVE_API_KEY } = require("../../config");

/**
 * 現在の期間を取得（"2025-10"形式）
 */
function getCurrentPeriod() {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  return `${year}-${month}`;
}

// 🔍 Perspective API を使って TOXICITY を検出
async function checkToxicity(text) {
  const response = await axios.post(
    "https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze",
    {
      comment: { text },
      languages: ["ja"],
      requestedAttributes: { TOXICITY: {} },
    },
    {
      params: { key: PERSPECTIVE_API_KEY },
    }
  );

  const score = response.data.attributeScores.TOXICITY.summaryScore.value;
  return score;
}

// 🤖 Gemini（ChatGPT相当）で解答の妥当性を判定
async function validateWithAI(questionText, answerText) {
  const instruction = `次の文章が「質問（${questionText}）」の「適切な解答」として成立しているか判定してください。適切なら「OK」、意味が不明瞭なら「NG」、不適切なら「REVIEW」。`;

  const response = await model.generateContent({
    systemInstruction: instruction,
    contents: [{ role: "user", parts: [{ text: answerText }] }],
  });

  const raw = response.response.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
  return raw;
}

// 🔥 Cloud Functions本体
exports.addAnswer = onCall(async (request) => {
  try {
    const { questionId, answerText, questionText } = request.data;
    const userId = request.auth.uid;

    if (!userId) {
      throw new functions.https.HttpsError("unauthenticated", "User is not authenticated");
    }

    if (!questionId || !answerText || !questionText) {
      throw new functions.https.HttpsError("invalid-argument", "Invalid request data");
    }

    // 1. Perspectiveで暴言チェック
    const toxicity = await checkToxicity(answerText);
    const toxicityIsOK = toxicity < 0.7;

    // 2. Geminiで内容チェック
    const aiResult = await validateWithAI(questionText, answerText);
    const aiResultNormalized = aiResult?.trim()?.toUpperCase();

    // 3. status を条件に応じて決定
    let status = "approved";

    if (!toxicityIsOK || aiResultNormalized === "NG") {
      status = "rejected";
    } else if (aiResultNormalized === "REVIEW") {
      status = "pending_review";
    }

    // 4. Firestoreに保存
    const answerDocId = `${questionId}_${userId}`;
    await db
      .collection("questions")
      .doc(questionId)
      .collection("answers")
      .doc(answerDocId)
      .set({
        text: answerText,
        createdBy: userId,
        createdAt: FieldValue.serverTimestamp(),
        toxicityScore: toxicity,
        aiCheckResult: aiResult,
        status,
      });

    // 🔥 お気に入り（回答済み）として保存
    await db.collection("users").doc(userId).set({
      favoriteQuestions: FieldValue.arrayUnion(questionId)
    }, { merge: true });

    // 📊 月次貢献度に記録（承認された回答のみ）
    if (status === "approved") {
      const currentPeriod = getCurrentPeriod();
      const contributionRef = db
        .collection("monthly_contributions")
        .doc(currentPeriod)
        .collection("users")
        .doc(userId);

      const contributionDoc = await contributionRef.get();

      if (contributionDoc.exists) {
        // 既存の貢献度に追加
        await contributionRef.update({
          total_points: FieldValue.increment(1), // +1ポイント
          answer_count: FieldValue.increment(1),
          answers: FieldValue.arrayUnion(answerDocId),
          updated_at: FieldValue.serverTimestamp(),
        });
      } else {
        // 新規作成
        await contributionRef.set({
          user_id: userId,
          period: currentPeriod,
          total_points: 1,
          answer_count: 1,
          best_answer_count: 0,
          answers: [answerDocId],
          created_at: FieldValue.serverTimestamp(),
          updated_at: FieldValue.serverTimestamp(),
        });
      }

      console.log(`✅ ${userId} earned 1 point for ${currentPeriod} (answer: ${answerDocId})`);
    }

    return { message: "回答を追加しました" };
  } catch (error) {
    console.error("❌ 回答の追加に失敗:", error);
    throw new functions.https.HttpsError("internal", error.message || "Internal server error");
  }
});
