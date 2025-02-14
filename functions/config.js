const admin = require("firebase-admin");
const { Firestore } = require("firebase-admin/firestore");
const { VertexAI } = require("@google-cloud/vertexai");

admin.initializeApp();

const project = process.env.GCLOUD_PROJECT;
const location = process.env.vertexai_location || "us-central1";
const vertexAI = new VertexAI({ project: project, location: location });
const model = vertexAI.getGenerativeModel({ model: "gemini-1.5-flash-001" });

module.exports = {
  admin,
  Firestore,
  model
};
