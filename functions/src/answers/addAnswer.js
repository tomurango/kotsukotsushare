const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const db = getFirestore();

exports.addAnswer = async (req, res) => {
  try {
    const { questionId, answerText, userId } = req.body;

    if (!questionId || !answerText || !userId) {
      return res.status(400).json({ error: "Invalid request data" });
    }

    // 🔥 Firestore の `answers` コレクションに保存
    await db.collection("questions").doc(questionId).collection("answers").add({
      text: answerText,
      createdBy: userId,
      createdAt: FieldValue.serverTimestamp(),
    });

    return res.status(200).json({ message: "回答を追加しました" });
  } catch (error) {
    console.error("❌ 回答の追加に失敗:", error);
    return res.status(500).json({ error: "Internal server error" });
  }
};
