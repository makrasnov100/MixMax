const checkIsAuthenticated = ({ context }) => {
  const uid = context?.auth?.uid;
  if (!uid) {
    throw new Error("Authentication Required!");
  }

  return uid;
};

module.exports = {
  checkIsAuthenticated,
};
