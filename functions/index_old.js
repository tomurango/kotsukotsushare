
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {
    Firestore,
  } = require("firebase-admin/firestore");
const { VertexAI } = require("@google-cloud/vertexai");
//const genAI = new GoogleGenerativeAI(process.env.gemini_api_key);
const project = process.env.GCLOUD_PROJECT;
const location = process.env.vertexai_location || "us-central1";
const vertexAI = new VertexAI({project: project, location: location});
const model = vertexAI.getGenerativeModel({ model: "gemini-1.5-flash-001" });

admin.initializeApp();

exports.getAIAdvice = functions.https.onCall(async (data, context) => {
    try {
      const userMessage = data.data.userMessage || "";
      const pastMessages = data.data.pastMessages || [];
      const userId = data.data.userId || "";
      const cardId = data.data.cardId || "";
      const memoId = data.data.memoId || "";
  
      // 必須項目のチェック
      if (!userMessage || !userId || !cardId || !memoId) {
        throw new functions.https.HttpsError("invalid-argument", "必要なデータが不足しています。");
      }
  
      let request = {};
      if (pastMessages.length === 0) {
        request = {
          systemInstruction: "これは最初のメッセージです。このメモの内容についてアドバイスしてください。",
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
      // 最初の投稿の場合はユーザーのメッセージも保存
      if (pastMessages.length === 0) {
        const userMessageData = {
            content: userMessage,
            isAI: false,
            createdAt: Firestore.FieldValue.serverTimestamp()
        };
        await firestoreRef.add(userMessageData);
      }
      
      // 正しい候補を取得
      const aiResponse = response.response.candidates[0].content.parts[0].text;
  
      // Firestoreに保存
      const aiAdviceData = {
        content: aiResponse,
        isAI: true,
        createdAt: Firestore.FieldValue.serverTimestamp()
      };
  
      await firestoreRef.add(aiAdviceData);
  
      return aiResponse || "";
    } catch (error) {
      console.error("Error calling Gemini API:", error);
      throw new functions.https.HttpsError("internal", "AIアドバイスの取得に失敗しました。");
    }
  });
  
