const functions = require("firebase-functions");
const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}

exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
  // Optional: 
  //  - check if created user is an anonymous user
  // const isAnonymous = user.providerData.length === 0;

  //Create a new user document in the users collection
  const docRef = admin.firestore().collection("Users").doc(user.uid);
  return docRef.set({
    id: user.uid,
    email: user.email,
    displayName: user.displayName,
    photoURL: user.photoURL,
    phoneNumber: user.phoneNumber,
    providerData: user.providerData,
    createdAt: new Date().getTime(),
    updatedAt: new Date().getTime(),
  });
});

