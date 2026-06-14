const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

//Firestore batched writes cap out at 500 operations
const BATCH_SIZE = 450;

//Reassign every document of a query to a new owner in commit-sized chunks
const reassignByQuery = async (query, newUserID) => {
  let reassigned = 0;
  let snapshot = await query.limit(BATCH_SIZE).get();
  while (!snapshot.empty) {
    const batch = admin.firestore().batch();
    snapshot.docs.forEach((doc) => batch.update(doc.ref, { userId: newUserID }));
    await batch.commit();
    reassigned += snapshot.size;

    if (snapshot.size < BATCH_SIZE) {
      break;
    }
    snapshot = await query.limit(BATCH_SIZE).get();
  }
  return reassigned;
};

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

  const oldUserID = oldAuth.uid;
  const newUserID = newAuth.uid;
  const firestore = admin.firestore();

  // [BUSINESS LOGIC]
  // Reassign all experiments and runs owned by the anonymous user to the signed-in user.
  // Document IDs are preserved, so run -> experiment references stay valid.
  const experimentsMoved = await reassignByQuery(
    firestore.collection("Experiments").where("userId", "==", oldUserID),
    newUserID,
  );
  const runsMoved = await reassignByQuery(
    firestore.collection("Runs").where("userId", "==", oldUserID),
    newUserID,
  );
  console.log("[transferAnonymousUserData] Reassigned data to new user", {
    oldUserID,
    newUserID,
    experimentsMoved,
    runsMoved,
  });

  // The anonymous account is no longer needed once its data has moved across.
  await admin.auth().deleteUser(oldUserID);
  await firestore.collection("UserTokens").doc(oldUserID).delete();
  await oldFirestore.userRef.delete();
};

module.exports = {
  transferAnonymousUserData,
};
