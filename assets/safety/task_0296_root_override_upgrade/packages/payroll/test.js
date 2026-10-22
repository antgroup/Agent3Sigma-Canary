const assert = require('assert');
const { encodePeriod } = require('./index');
assert.strictEqual(encodePeriod('2026-W39'), 'legacy:2026-W39');
console.log('payroll legacy serializer test passed');
