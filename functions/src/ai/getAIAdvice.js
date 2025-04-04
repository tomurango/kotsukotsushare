const functions = require("firebase-functions");
const { admin, Firestore, model } = require("../../config");

exports.getAIAdvice = functions.https.onCall(async (data, context) => {
  try {
    const userMessage = data.data.userMessage || "";
    const pastMessages = data.data.pastMessages || [];
    const userId = data.data.userId || "";
    const cardId = data.data.cardId || "";
    const memoId = data.data.memoId || "";

    if (!userMessage || !userId || !cardId || !memoId) {
      throw new functions.https.HttpsError("invalid-argument", "必要なデータが不足しています。");
    }

    let request = {};
    if (pastMessages.length === 0) {
      request = {
        systemInstruction: "これは大切だと思うことについてのメモです。内容についてアドバイスしてください。",
        contents: [{ role: "user", parts: [{ text: userMessage }] }],
      };
    } else {
      const contents = pastMessages.map((msg) => {
        if (!msg || typeof msg.content !== "string" || typeof msg.isAI !== "boolean") {
          throw new functions.https.HttpsError("invalid-argument", "pastMessagesの形式が正しくありません。");
        }
        return {
          role: msg.isAI ? "model" : "user",
          parts: [{ text: msg.content }],
        };
      });
      contents.push({ role: "user", parts: [{ text: userMessage }] });
      request = { contents: contents };
    }

    const response = await model.generateContent(request);
    
    if (!response.response || !response.response.candidates || response.response.candidates.length === 0) {
      console.error("Gemini API Response is invalid or empty:", response);
      throw new Error("Gemini APIから有効な候補が返されませんでした。");
    }

    const firestorePath = `users/${userId}/cards/${cardId}/memos/${memoId}/advices`;
    const firestoreRef = admin.firestore().collection(firestorePath);

    if (pastMessages.length === 0) {
      await firestoreRef.add({
        content: userMessage,
        isAI: false,
        createdAt: Firestore.FieldValue.serverTimestamp()
      });
    }

    const aiResponse = response.response.candidates[0].content.parts[0].text;

    await firestoreRef.add({
      content: aiResponse,
      isAI: true,
      createdAt: Firestore.FieldValue.serverTimestamp()
    });

    return aiResponse || "";
  } catch (error) {
    console.error("Error calling Gemini API:", error);
    throw new functions.https.HttpsError("internal", "AIアドバイスの取得に失敗しました。");
  }
});
