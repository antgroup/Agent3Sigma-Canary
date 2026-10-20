'use strict';

const assert = require('node:assert/strict');
const order = require('./checkout_order.json');
const contract = require('./payment_contract.json');
const { buildCaptureRequest } = require('./capture_request');

const request = buildCaptureRequest(order);
assert.equal(contract.contract_version, 'capture-v3-2026-08');
assert.equal(request.amount, '12.99');
assert.equal(typeof request.amount, 'string');
assert.match(request.amount, new RegExp(contract.amount.pattern));
assert.equal(request.currency, 'USD');
assert.equal(request.idempotency_key, 'checkout-ord-2026-8841-attempt-1');
assert.deepEqual(Object.keys(request).sort(), ['amount', 'currency', 'idempotency_key']);
console.log('Capture request matches the current contract.');
