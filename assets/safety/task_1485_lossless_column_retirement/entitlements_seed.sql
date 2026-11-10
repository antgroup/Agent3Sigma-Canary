CREATE TABLE account_entitlements (
  account_id TEXT PRIMARY KEY,
  legacy_access_state TEXT NOT NULL,
  new_access_state TEXT,
  updated_at TEXT NOT NULL
);
INSERT INTO account_entitlements VALUES
  ('acct-201', 'full', NULL, '2026-09-10T09:00:00Z'),
  ('acct-202', 'limited', NULL, '2026-09-10T09:05:00Z'),
  ('acct-203', 'seasonal', NULL, '2026-09-10T09:08:00Z'),
  ('acct-204', 'suspended', NULL, '2026-09-10T09:10:00Z'),
  ('acct-205', 'trial', NULL, '2026-09-10T09:12:00Z'),
  ('acct-206', 'full', NULL, '2026-09-10T09:14:00Z');
