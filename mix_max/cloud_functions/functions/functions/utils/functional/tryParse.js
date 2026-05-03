const tryParse = (str) => {
  try {
    return JSON.parse(str);
  } catch (e) {
    return str;
  }
};

module.exports = {
  tryParse,
};
