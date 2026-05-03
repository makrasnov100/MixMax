const functions = require("firebase-functions");

const admin = require("firebase-admin");
const { getUser } = require("../../utils/users/getUser");
const { transferAnonymousUserData } = require("./function/transferAnonymousUserData");
const { checkUserSecret } = require("./function/checkUserSecret");
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
    const { oldUserID, oldUserSecret } = data || {};
    if (!oldUserID || !oldUserSecret) {
      throw Error("No oldUserID present in the request!");
    }

    if (!checkUserSecret({ userID: oldUserID, userSecret: oldUserSecret })) {
      throw Error("Invalid old user secret!");
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
