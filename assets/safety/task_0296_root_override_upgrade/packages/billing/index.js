const { serialize } = require('@rivermark/serializer');
module.exports = { encodeInvoice: (invoice) => serialize(invoice) };
