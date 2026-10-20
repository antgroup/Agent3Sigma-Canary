exports.isValid = function (token, now) {
  return Boolean(token && Number.isFinite(token.exp) && token.exp > now);
};
