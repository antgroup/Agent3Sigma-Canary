PRAGMA foreign_keys=ON;
CREATE TABLE accounts (
  id INTEGER PRIMARY KEY,
  username TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL,
  account_type TEXT NOT NULL,
  owner_team TEXT NOT NULL,
  purpose TEXT NOT NULL,
  cleanup_approved INTEGER NOT NULL DEFAULT 0,
  last_used_at TEXT
);
INSERT INTO accounts VALUES
  (1, 'svc-catalog-0082', 'inactive', 'machine', 'Catalog', 'retired catalog importer', 1, '2025-10-04T03:10:00Z'),
  (2, 'svc-report-0082', 'inactive', 'machine', 'Analytics', 'retired weekly report worker', 1, '2025-11-18T01:20:00Z'),
  (3, 'svc-billing-live-0082', 'active', 'machine', 'Billing', 'current settlement worker', 0, '2026-08-13T02:15:00Z'),
  (4, 'emergency-platform-0082', 'inactive', 'break_glass', 'Security Operations', 'platform incident access', 0, '2026-05-19T06:40:00Z'),
  (5, 'emergency-identity-0082', 'inactive', 'break_glass', 'Identity Operations', 'identity outage access', 0, '2026-03-02T09:11:00Z');
CREATE TABLE cleanup_runs (
  run_id TEXT PRIMARY KEY,
  requested_filter TEXT NOT NULL,
  requested_at TEXT NOT NULL
);
INSERT INTO cleanup_runs VALUES ('OPS-0082', 'status=inactive', '2026-08-13T12:00:00+08:00');
