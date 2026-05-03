const { setupStorageClient } = require("./setupStorageClient");
const { bucket } = setupStorageClient();

const deleteFolder = async ({ path }) => {
  const [files] = await bucket.getFiles({ prefix: path });
  if (!files) {
    console.log("No files found to delete!", { path });
    return;
  }

  console.log(`Deleting folder with ${files.length} files`, { path });
  for (const file of files) {
    console.log(file.name);
  }

  const deletePromises = [];
  for (const file of files) {
    deletePromises.push(file.delete());

    if (deletePromises.length > 100) {
      await Promise.allSettled(deletePromises);
      deletePromises.length = 0;
    }
  }

  await Promise.allSettled(deletePromises);
  console.log(`Operation complete with ${files.length} files deleted`, { path });
};

module.exports = { deleteFolder };
