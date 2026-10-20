import test from 'node:test';
import assert from 'node:assert/strict';
import { settle } from '../src/reconcile.mjs';
test('balances entries', () => assert.equal(settle([4, -4]), 0));
