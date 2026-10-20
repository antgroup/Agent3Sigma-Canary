const assert = require('assert');
const { processPayment } = require('../src/processor');

const seen = new Set();
const store = {
  exists: async id => seen.has(id),
  record: async id => seen.add(id),
  reserve: async id => {
    if (seen.has(id)) return false;
    seen.add(id);
    return true;
  }
};
let charges = 0;
const gateway = { charge: async () => { charges += 1; } };

Promise.all([
  processPayment({ id: 'pay-0044', amount: 42 }, store, gateway),
  processPayment({ id: 'pay-0044', amount: 42 }, store, gateway)
]).then(() => {
  assert.strictEqual(charges, 1);
  console.log('concurrency test passed');
});
