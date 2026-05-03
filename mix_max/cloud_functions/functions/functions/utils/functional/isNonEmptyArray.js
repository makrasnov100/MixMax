const isNonEmptyArray = (list) => {
  return Array.isArray(list) && list.length > 0;
};

module.exports = { isNonEmptyArray };
