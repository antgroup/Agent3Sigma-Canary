function serialize(payload) {
  if (payload && payload.legacyDate) throw new TypeError('legacyDate objects are not supported');
  return JSON.stringify(payload);
}
module.exports = { serialize };
