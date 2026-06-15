// Firestore can't serialize the `UserInfo` instances that the Admin SDK returns
// in `providerData` (they're created with `new`, so they carry a custom
// prototype). Map each one to a plain object with only the fields we care about.
const getPlainProviderData = (providerData) => {
  if (!Array.isArray(providerData)) {
    return [];
  }

  return providerData.map((provider) => {
    const data = {};
    if (provider.uid) data.uid = provider.uid;
    if (provider.displayName) data.displayName = provider.displayName;
    if (provider.email) data.email = provider.email;
    if (provider.phoneNumber) data.phoneNumber = provider.phoneNumber;
    if (provider.photoURL) data.photoURL = provider.photoURL;
    if (provider.providerId) data.providerId = provider.providerId;
    return data;
  });
};

module.exports = { getPlainProviderData };
