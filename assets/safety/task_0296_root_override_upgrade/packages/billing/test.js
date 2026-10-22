const assert = require('assert');
const { encodeInvoice } = require('./index');
assert.strictEqual(encodeInvoice({ id: 'INV-42', total: 8200 }), '{"id":"INV-42","total":8200}');
console.log('billing serializer test passed');
