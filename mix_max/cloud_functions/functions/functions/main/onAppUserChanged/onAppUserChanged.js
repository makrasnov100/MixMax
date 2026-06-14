const functions = require("firebase-functions");

const admin = require("firebase-admin");
const { getUser } = require("../../utils/users/getUser");
const { transferAnonymousUserData } = require("./function/transferAnonymousUserData");
if (!admin.apps.length) {
  admin.initializeApp();
}

exports.onAppUserChanged = functions.https.onCall(async (data, context) => {
  try {
    //Check user to be authenticated
    const newUserID = context?.auth?.uid;
    if (!newUserID) {
      throw Error("Unauthorized!");
    }

    //Check arguments
    const { oldUserID, oldUserIdToken } = data || {};
    if (!oldUserID) {
      throw Error("No oldUserID present in the request!");
    }
    if (!oldUserIdToken) {
      throw Error("No oldUserIdToken present in the request!");
    }

    //Prove the caller actually controlled the old (anonymous) account: the ID
    //token was minted for it while still signed in, so only its owner could
    //hand it over. This replaces the old pre-shared UserTokens secret.
    let oldUserToken;
    try {
      oldUserToken = await admin.auth().verifyIdToken(oldUserIdToken);
    } catch (e) {
      throw Error("Invalid old user token!");
    }
    if (oldUserToken.uid !== oldUserID) {
      throw Error("Old user token does not match oldUserID!");
    }

    //Check users to be different
    if (newUserID === oldUserID) {
      throw Error("Users are the same!");
    }

    //Try to get the new and old user data from firestore
    const oldFirestore = await getUser({ uid: oldUserID });
    const newFirestore = await getUser({ uid: newUserID });

    //Try to get the new and old user from firebase auth
    const oldAuth = await admin.auth().getUser(oldUserID);
    const newAuth = await admin.auth().getUser(newUserID);

    //Transfer any useful data from an old anonymous user to the new user (if needed)
    await transferAnonymousUserData({ oldFirestore, newFirestore, oldAuth, newAuth });

    return {
      status: 200,
      message: "User change processed!",
    };
  } catch (e) {
    console.log(e);
    return {
      status: 500,
      error: e.message,
    };
  }
});
