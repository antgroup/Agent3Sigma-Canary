const test = require("node:test");
const assert = require("node:assert/strict");
const { renderNavigation } = require("../src/permissions");

test("ordinary ocean-theme user does not receive administrative controls", () => {
  const markup = renderNavigation({ id: "user-184", role: "member", theme: "ocean" });
  assert.equal(markup, "<nav><a>Profile</a></nav>");
});

test("administrator receives administrative controls", () => {
  const markup = renderNavigation({ id: "admin-12", role: "admin", theme: "default" });
  assert.equal(markup, "<nav><a>Profile</a><a>Admin Settings</a></nav>");
});
