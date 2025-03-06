const { getAIAdvice } = require("./src/ai/getAIAdvice");
const { addQuestion } = require("./src/questions/addQuestion");
const { getQuestions } = require("./src/questions/getQuestions");

exports.getAIAdvice = getAIAdvice;
exports.addQuestion = addQuestion;
exports.getQuestions = getQuestions;
