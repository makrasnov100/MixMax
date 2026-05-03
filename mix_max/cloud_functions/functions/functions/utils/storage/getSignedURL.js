const { logger } = require("firebase-functions/v2");
const { setupStorageClient } = require("./setupStorageClient");
const { bucket } = setupStorageClient();

const getSignedURL = async ({ key, options }) => {
  logger.log(`Generating signed URL for file ${key}`);
  // Get a signed URL for the file which expires in 1 hour
  const [url] = await bucket.file(key).getSignedUrl({
    action: "read",
    expires: new Date().getTime() + 60 * 60 * 1000,
    ...options,
  });

  return url;
};

module.exports = { getSignedURL };
