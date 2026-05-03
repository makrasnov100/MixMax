const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

//Retrieves a user from firestore database
const getUser = async ({ uid }) => {
  console.log("[getUser] at start - ", { uid });

  const invalidOutput = {
    user: null,
    userRef: null,
  };

  if (!uid) {
    return invalidOutput;
  }

  const db = admin.firestore();
  const userSnap = await db.collection("Users").doc(uid).get();

  if (userSnap) {
    return {
      user: userSnap.data(),
      userRef: userSnap.ref,
    };
  } else {
    return invalidOutput;
  }
};

module.exports = { getUser };
