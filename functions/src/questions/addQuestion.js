const { onCall } = require("firebase-functions/v2/https");
const { admin, db, FieldValue, model, PERSPECTIVE_API_KEY } = require("../../config");

exports.addQuestion = onCall(async (request) => {
  try {
    console.log("request.auth:", request.auth);

    // 認証チェック（v2では context.auth ではなく request.auth を使用）
    let userId;
    if (request.auth) {
      console.log("🟢 request.auth が利用可能");
      userId = request.auth.uid;
    } else if (request.data?.idToken) {
      console.log("🟠 request.auth が undefined。data.idToken を検証中...");
      const decodedToken = await admin.auth().verifyIdToken(request.data.idToken);
      userId = decodedToken.uid;
    } else {
      console.error("🔴 認証エラー: ID Token も request.auth もなし");
      throw new Error("unauthenticated");
    }

    console.log("🟢 認証成功 - UID:", userId);

    const { question } = request.data;
    if (!question || question.trim() === "") {
      throw new Error("質問の内容が必要です。");
    }

    const cleanedText = question.trim();
    console.log(PERSPECTIVE_API_KEY);

    const perspectiveResponse = await fetch(
        `https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze?key=${PERSPECTIVE_API_KEY}`,
        {
          method: "POST",
          body: JSON.stringify({
            comment: { text: cleanedText },
            languages: ["en", "ja"], // 🔥 言語を拡張
            requestedAttributes: {
              TOXICITY: {},
              SEVERE_TOXICITY: {}, // 🔥 追加
              INSULT: {},
              PROFANITY: {},
              THREAT: {}, // 🔥 追加
              IDENTITY_ATTACK: {} // 🔥 追加
            },
          }),
          headers: { "Content-Type": "application/json" },
        }
      );
      
    const perspectiveData = await perspectiveResponse.json();
    console.log("🔍 Perspective API Response:", JSON.stringify(perspectiveData, null, 2)); // 🔥 APIのレスポンスを確認
    
    const toxicityScore = perspectiveData.attributeScores?.TOXICITY?.summaryScore?.value || 0;
    const severeToxicityScore = perspectiveData.attributeScores?.SEVERE_TOXICITY?.summaryScore?.value || 0;
    const insultScore = perspectiveData.attributeScores?.INSULT?.summaryScore?.value || 0;
    const profanityScore = perspectiveData.attributeScores?.PROFANITY?.summaryScore?.value || 0;
    const threatScore = perspectiveData.attributeScores?.THREAT?.summaryScore?.value || 0;
    const identityAttackScore = perspectiveData.attributeScores?.IDENTITY_ATTACK?.summaryScore?.value || 0;
    
    // console.log(`🟢 TOXICITY: ${toxicityScore}, SEVERE_TOXICITY: ${severeToxicityScore}, INSULT: ${insultScore}, PROFANITY: ${profanityScore}, THREAT: ${threatScore}, IDENTITY_ATTACK: ${identityAttackScore}`);

    let status = "approved"; // デフォルトは承認
    if (toxicityScore > 0.7 || insultScore > 0.7 || profanityScore > 0.7) {
      status = "rejected"; // 明らかに問題がある
    } else if (toxicityScore > 0.3 || insultScore > 0.3 || profanityScore > 0.3) {
      status = "pending_review"; // 要確認
    }

    // 🌟 Gemini AI で「質問として成立しているか？」をチェック
    let geminiResponseText = "";
    if (status === "approved") {
      const geminiResponse = await model.generateContent({
        systemInstruction: "次の文章が「適切な質問」として成立しているか判定してください。適切なら「OK」、意味が不明瞭なら「NG」、不適切なら「REVIEW」。",
        contents: [{ role: "user", parts: [{ text: cleanedText }] }],
      });
      
      if (!geminiResponse.response || !geminiResponse.response.candidates || geminiResponse.response.candidates.length === 0) {
        console.error("Gemini API Response is invalid or empty:", response);
        throw new Error("Gemini APIから有効な候補が返されませんでした。");
      }

      geminiResponseText = geminiResponse.response.candidates[0].content.parts[0].text;
      //console.log("Gemini Response Text:", geminiResponseText);
      
      if (geminiResponseText.includes("NG")) {
        status = "rejected";
      } else if (geminiResponseText.includes("REVIEW")) {
        status = "pending_review";
      }
    }

    // 🌟 Firestore に質問を保存
    const questionRef = await db.collection("questions").add({
      text: cleanedText,
      createdBy: userId,
      timestamp: FieldValue.serverTimestamp(),
      random: Math.random(), // ランダム取得のための数値
      status, // AI の判断結果
      moderationResults: {
        perspective: {
          toxicity: toxicityScore,
          insult: insultScore,
          profanity: profanityScore,
        },
        gemini: {
          response: geminiResponseText,
        },
      },
    });

    return { success: true, questionId: questionRef.id, status };
  } catch (error) {
    console.error("Error:", error);
    throw new Error("エラーが発生しました。");
  }
});
