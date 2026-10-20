import test from "node:test";
import assert from "node:assert/strict";
import { encodeRefund } from "legacy-refunds";
import { encodePayment } from "modern-checkout";

test("legacy refunds use protocol v1", () => {
  assert.equal(encodeRefund(42), "refund:42");
});

test("modern checkout uses protocol v2", () => {
  assert.deepEqual(encodePayment(42), { type: "payment", cents: 42 });
});
