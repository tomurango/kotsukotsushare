const { onCall } = require("firebase-functions/v2/https");
const functions = require("firebase-functions");
const axios = require("axios");
const { db, FieldValue, model, PERSPECTIVE_API_KEY } = require("../../config");

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

    return { message: "回答を追加しました" };
    /*return {
      message: reviewRequired
        ? "内容に問題の可能性があるため確認が必要です"
        : "回答を追加しました",
      toxicity,
      aiResult,
      reviewRequired,
    };*/



  } catch (error) {
    console.error("❌ 回答の追加に失敗:", error);
    throw new functions.https.HttpsError("internal", error.message || "Internal server error");
  }
});
