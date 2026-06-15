const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

// Copies the caller's auth profile (email / name / photo) onto their Firestore
// Users doc. `onUserCreated` only fires when the auth record is first created —
// for a guest that's the *anonymous* account, which has no email. When that
// guest later links Google/Apple the uid is unchanged, so no create event fires
// and the doc keeps email: null. The client calls this right after a federated
// sign-in to backfill the now-populated email. Auth is the source of truth, so
// we read from admin.auth().getUser rather than trusting anything in `data`.
exports.syncUserProfile = functions.https.onCall(async (data, context) => {
  try {
    const uid = context?.auth?.uid;
    if (!uid) {
      throw Error("Unauthorized!");
    }

    const authUser = await admin.auth().getUser(uid);

    await admin.firestore().collection("Users").doc(uid).set(
      {
        email: authUser.email ?? null,
        displayName: authUser.displayName ?? null,
        photoURL: authUser.photoURL ?? null,
        providerData: authUser.providerData,
        updatedAt: new Date().getTime(),
      },
      { merge: true },
    );

    return {
      status: 200,
      message: "User profile synced!",
    };
  } catch (e) {
    console.log(e);
    return {
      status: 500,
      error: e.message,
    };
  }
});
