const getUserSecret = require("./functions/main/getUserSecret/getUserSecret");
const onUserCreated = require("./functions/main/onUserCreated/onUserCreated");
const onAppUserChanged = require("./functions/main/onAppUserChanged/onAppUserChanged");

exports.getUserSecret = getUserSecret.getUserSecret;
exports.onUserCreated = onUserCreated.onUserCreated;
exports.onAppUserChanged = onAppUserChanged.onAppUserChanged;
