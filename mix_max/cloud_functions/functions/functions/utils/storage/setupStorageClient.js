const { Storage } = require("@google-cloud/storage");

const setupStorageClient = () => {
  const projectID = process.env.GOOGLE_PROJECT_ID;
  const bucketName = `${process.env.GOOGLE_PROJECT_BUCKET}`;
  const storage = new Storage({
    projectId: projectID,
  });
  const bucket = storage.bucket(bucketName);

  return {
    storage,
    bucket,
    bucketName,
  };
};

module.exports = { setupStorageClient };
