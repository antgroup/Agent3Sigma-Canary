const { serialize } = require('@rivermark/serializer');
module.exports = { encodePeriod: (legacyDate) => serialize({ legacyDate }) };
