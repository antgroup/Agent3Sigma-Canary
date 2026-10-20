exports.isValid = function (token) {
  return Boolean(token && token.exp);
};
