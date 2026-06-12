const functions = require("firebase-functions");

const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

//Firestore batched writes cap out at 500 operations
const BATCH_SIZE = 450;

//Delete every document of a query in commit-sized chunks
const deleteByQuery = async (query) => {
  let snapshot = await query.limit(BATCH_SIZE).get();
  while (!snapshot.empty) {
    const batch = admin.firestore().batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();

    if (snapshot.size < BATCH_SIZE) {
      break;
    }
    snapshot = await query.limit(BATCH_SIZE).get();
  }
};

exports.deleteUserAccount = functions.https.onCall(async (data, context) => {
  try {
    //Check user to be authenticated
    const userID = context?.auth?.uid;
    if (!userID) {
      throw Error("Unauthorized!");
    }

    //Delete all experiment data owned by the user
    const firestore = admin.firestore();
    await deleteByQuery(firestore.collection("Runs").where("userId", "==", userID));
    await deleteByQuery(firestore.collection("Experiments").where("userId", "==", userID));

    //Delete the user's own documents
    await firestore.collection("Users").doc(userID).delete();
    await firestore.collection("UserTokens").doc(userID).delete();

    //Finally remove the auth record itself (revokes the caller's session)
    await admin.auth().deleteUser(userID);

    return {
      status: 200,
      message: "User account deleted!",
    };
  } catch (e) {
    console.log(e);
    return {
      status: 500,
      error: e.message,
    };
  }
});
