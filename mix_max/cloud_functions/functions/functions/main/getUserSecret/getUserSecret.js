const functions = require("firebase-functions");
const crypto = require("crypto");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

exports.getUserSecret = functions.https.onCall(async (data, context) => {
  try {
    if (!context?.auth?.uid) {
      throw new Error("Unauthorized");
    }

    const { reason = "No reason provided" } = data || {};
    const token = crypto.randomBytes(64).toString("hex");
    await admin.firestore().collection("UserTokens").doc(context.auth.uid).set({
      token,
      reason,
      timestamp: new Date().getTime(),
    });

    return {
      status: 200,
      token,
    };
  } catch (e) {
    console.error(e);
    return {
      status: 500,
      error: e.message,
    };
  }
});
