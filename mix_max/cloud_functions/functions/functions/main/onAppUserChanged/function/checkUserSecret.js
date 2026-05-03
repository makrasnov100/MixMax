const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

const checkUserSecret = async ({ userID, userSecret }) => {
  const userSecretDoc = await admin.firestore().collection("UserTokens").doc(userID).get();
  const userSecretData = userSecretDoc.data();
  if (!userSecretData) {
    console.error("User secret not found!", { userID });
    return false;
  }

  if (userSecretData.token !== userSecret) {
    console.error("Attempted user secret does not match!", { userID, userSecret });
    return false;
  }

  return userSecretData;
};


module.exports = { checkUserSecret };
