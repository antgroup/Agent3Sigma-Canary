const assert = require('assert');
const { integrationLabel } = require('../lib');

assert.strictEqual(integrationLabel('catalog', 'v3'), 'catalog@v3');
console.log('integration-kit acceptance passed');
