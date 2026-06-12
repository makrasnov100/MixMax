const getUserSecret = require("./functions/main/getUserSecret/getUserSecret");
const onUserCreated = require("./functions/main/onUserCreated/onUserCreated");
const onAppUserChanged = require("./functions/main/onAppUserChanged/onAppUserChanged");
const deleteUserAccount = require("./functions/main/deleteUserAccount/deleteUserAccount");

exports.getUserSecret = getUserSecret.getUserSecret;
exports.onUserCreated = onUserCreated.onUserCreated;
exports.onAppUserChanged = onAppUserChanged.onAppUserChanged;
exports.deleteUserAccount = deleteUserAccount.deleteUserAccount;
