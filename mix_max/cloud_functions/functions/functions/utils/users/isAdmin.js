const admin = require("firebase-admin");
if (!admin.apps.length) {
  admin.initializeApp();
}
const adminList = [
];

// returns true if user with the provided id is an admin
const isAdmin = async ({ uid }) => {
  try {
    const userRecord = await admin.auth().getUser(uid);
    //not admin if user doesnt not exist
    if (!userRecord) {
      return false;
    }

    //check if user email is in the admin list
    if (userRecord.email && adminList.includes(userRecord.email)) {
      return true;
    }

    //Not admin if not in admin list
    return false;
  } catch (e) {
    //Not admin if error
    return false;
  }
};

module.exports = { isAdmin };
