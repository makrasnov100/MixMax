const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

const transferAnonymousUserData = async ({ oldFirestore, newFirestore, oldAuth, newAuth }) => {
  //Check both users have database entries
  const oldUser = oldFirestore?.user;
  const newUser = newFirestore?.user;
  if (!oldUser || !newUser) {
    console.log("[transferAnonymousUserData] No firestore data for one of the users, skipping!");
    return;
  }

  //Check if old user is anonymous and new one is not
  const oldUserIsAnonymous = oldAuth?.providerData?.length === 0;
  const newUserIsAnonymous = newAuth?.providerData?.length === 0;
  if (!oldUserIsAnonymous || newUserIsAnonymous) {
    console.log("[transferAnonymousUserData] Old user is not anonymous or new user is anonymous, skipping!");
    return;
  }

  // [BUSINESS LOGIC]
  await admin.firestore().runTransaction(async (transaction) => {
    // Optional: add functions that handle transfer of other user data to the new fedederated account
    // - handle inspection and image data transfer (storage and firestore)
    // await transferUserInspectionData({ oldUserID: oldAuth.uid, newUserID: newAuth.uid });

    // Delete anonymous user from auth and firestore
    await admin.auth().deleteUser(oldAuth.uid);
    await transaction.delete(oldFirestore?.userRef);
  });
};

module.exports = {
  transferAnonymousUserData,
};
