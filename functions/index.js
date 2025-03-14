const { getAIAdvice } = require("./src/ai/getAIAdvice");
const { addQuestion } = require("./src/questions/addQuestion");
const { getQuestions } = require("./src/questions/getQuestions");
const { getAnswers } = require("./src/answers/getAnswers");
const { addAnswer } = require("./src/answers/addAnswer");

exports.getAIAdvice = getAIAdvice;
exports.addQuestion = addQuestion;
exports.getQuestions = getQuestions;
exports.getAnswers = getAnswers;
exports.addAnswer = addAnswer;
