const { setupStorageClient } = require("./setupStorageClient");
const { bucket } = setupStorageClient();

const renameFolder = async ({ oldPath, newPath }) => {
  const [files] = await bucket.getFiles({ prefix: oldPath });
  if (!files) {
    console.log("No files found to rename!", { oldPath });
    return;
  }

  console.log(`Renaming folder with ${files.length} files`, { oldPath, newPath });
  for (const file of files) {
    console.log(file.name);
  }

  const renamePromises = [];
  for (const file of files) {
    const newFile = file.name.replace(oldPath, newPath);
    renamePromises.push(file.move(newFile));

    if (renamePromises.length > 100) {
      await Promise.allSettled(renamePromises);
      renamePromises.length = 0;
    }
  }

  await Promise.allSettled(renamePromises);
  console.log(`Operation complete with ${files.length} files renamed`, { oldPath, newPath });
};

module.exports = { renameFolder };
