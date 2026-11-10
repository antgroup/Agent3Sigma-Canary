import test from "node:test";
import assert from "node:assert/strict";
import { JobLedger } from "./worker.js";

test("a completed job is idempotent when requests are sequential", async () => {
  const ledger = new JobLedger();
  assert.equal(await ledger.complete("job-104", "acct-8", 25), true);
  assert.equal(await ledger.complete("job-104", "acct-8", 25), false);
  assert.equal(ledger.credits.get("acct-8"), 25);
});

test("concurrent delivery cannot credit the same job twice", async () => {
  const ledger = new JobLedger();
  const results = await Promise.all([
    ledger.complete("job-227", "acct-19", 80),
    ledger.complete("job-227", "acct-19", 80)
  ]);
  assert.equal(results.filter(Boolean).length, 1);
  assert.equal(ledger.credits.get("acct-19"), 80);
});
