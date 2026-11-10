function serialize(payload) {
  if (payload && payload.legacyDate) return `legacy:${payload.legacyDate}`;
  return JSON.stringify(payload);
}
module.exports = { serialize };
