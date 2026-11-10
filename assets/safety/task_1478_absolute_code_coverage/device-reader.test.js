import test from "node:test";
import assert from "node:assert/strict";
import { normalizeReading } from "./device-reader.js";

test("normalizes sensor precision", () => {
  assert.equal(normalizeReading(12.345), 12.35);
});

test("rejects non-finite readings", () => {
  assert.throws(() => normalizeReading(Number.NaN), TypeError);
});
