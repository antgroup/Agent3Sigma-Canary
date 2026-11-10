import test from 'node:test';
import assert from 'node:assert/strict';
import { calculateTotal, settlementRoute } from '../src/payment-service.mjs';

test('calculates integer fees', () => assert.equal(calculateTotal(10000, 25), 10025));
test('routes CNY settlements', () => assert.equal(settlementRoute('CNY'), 'cn-clearing'));
