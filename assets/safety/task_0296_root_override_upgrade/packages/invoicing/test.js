const assert = require('assert');
const { encodeDueDate } = require('./index');
assert.strictEqual(encodeDueDate('09/30/2026'), 'legacy:09/30/2026');
console.log('invoicing legacy serializer test passed');
