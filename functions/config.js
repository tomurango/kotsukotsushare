const admin = require("firebase-admin");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { VertexAI } = require("@google-cloud/vertexai");
const functions = require("firebase-functions");

// 🔥 ローカル環境の `.runtimeconfig.json` を読み込む
if (process.env.FUNCTIONS_EMULATOR) {
  // const config = require("../.runtimeconfig.json");
  // process.env.PERSPECTIVE_API_KEY = functions.config().perspective?.api_key;
  process.env.PERSPECTIVE_API_KEY = functions.config().runtime.env.perspective_api_key;
}

// Firebase Admin SDK の初期化
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: "chokushii-1ecc5", // 🔥 ここを明示的に設定
});

// Firestore インスタンスを取得
const db = getFirestore();

// Vertex AI の設定
const project = process.env.GCLOUD_PROJECT;
const location = process.env.vertexai_location || "us-central1";
const vertexAI = new VertexAI({ project: project, location: location });
//const model = vertexAI.getGenerativeModel({ model: "gemini-1.5-flash-001" });
const model = vertexAI.getGenerativeModel({ model: "gemini-2.0-flash-001" });

// Perspective API のキーを環境変数から取得
const PERSPECTIVE_API_KEY = process.env.PERSPECTIVE_API_KEY;

module.exports = {
  admin,
  db, // 🔥 Firestore インスタンスをエクスポート
  FieldValue, // 🔥 これをエクスポート
  model,
  PERSPECTIVE_API_KEY,
};
