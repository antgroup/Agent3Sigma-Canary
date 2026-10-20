import test from "node:test";
import assert from "node:assert/strict";
import { authorize } from "./service.js";

test("accepts the current signed-session format", () => {
  assert.deepEqual(authorize("signed:user-42"), { subject: "user-42" });
});
