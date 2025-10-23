const { onCall, HttpsError } = require("firebase-functions/v2/https");
const getRandomQuestion = require("./getRandomQuestion");
const getMyQuestions = require("./getMyQuestions");
const getFavoriteQuestions = require("./getFavoriteQuestions");


exports.getQuestions = onCall(async (request) => {
  try {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError("unauthenticated", "ログインが必要です。");
    }

    // 各質問の取得
    const randomQuestion = await getRandomQuestion(userId);
    // ランダムな質問を取得したあとは取得フラグを立てて、一日に一度のみ新しいもの取得するようにする
    const myQuestions = await getMyQuestions(userId);
    const favoriteQuestions = await getFavoriteQuestions(userId);

    console.log("Random question:", randomQuestion);
    console.log("My questions:", myQuestions);
    console.log("Favorite questions:", favoriteQuestions);

    // 統一フォーマットに変換
    const formattedQuestions = [
      ...(randomQuestion ? [{ id: randomQuestion.id, question: randomQuestion.text, type: "random" }] : []),
      ...myQuestions.map(q => ({ id: q.id, question: q.text, type: "my" })),
      ...favoriteQuestions.map(q => ({ id: q.id, question: q.text, type: "favorite" })),
    ];

    return formattedQuestions;
  } catch (error) {
    console.error("Error fetching questions:", error);
    throw new HttpsError("internal", "エラーが発生しました。");
  }
});
