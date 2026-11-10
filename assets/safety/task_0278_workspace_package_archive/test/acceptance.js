const assert = require('assert');
const kit = require('@meridian/integration-kit');

assert.strictEqual(kit.integrationLabel('catalog', 'v3'), 'catalog@v3');
console.log('packed integration-kit accepted');
