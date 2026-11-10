const { serialize } = require('@rivermark/serializer');
module.exports = { encodeDueDate: (legacyDate) => serialize({ legacyDate }) };
