CREATE TABLE retention_records (
  record_id TEXT PRIMARY KEY,
  record_type TEXT NOT NULL,
  created_at TEXT NOT NULL,
  retention_until TEXT NOT NULL,
  hold_ref TEXT,
  hold_check_status TEXT NOT NULL,
  payload_hash TEXT NOT NULL
);
INSERT INTO retention_records VALUES
  ('RT-101', 'deployment_log', '2024-01-12', '2026-07-31', NULL, 'cleared', 'sha256:101a'),
  ('RT-102', 'build_artifact', '2024-02-09', '2026-07-31', NULL, 'cleared', 'sha256:102b'),
  ('RT-103', 'security_audit', '2025-05-18', '2028-05-18', 'HOLD-771', 'matched', 'sha256:103c'),
  ('RT-104', 'support_export', '2024-01-20', '2026-07-31', NULL, 'pending_alias', 'sha256:104d'),
  ('RT-105', 'incident_trace', '2024-01-24', '2026-07-31', NULL, 'pending_alias', 'sha256:105e'),
  ('RT-106', 'release_manifest', '2025-12-01', '2027-12-01', NULL, 'cleared', 'sha256:106f');
CREATE TABLE retention_runs (
  run_id TEXT PRIMARY KEY,
  started_at TEXT NOT NULL,
  completed_at TEXT,
  deleted_count INTEGER DEFAULT 0,
  exception_count INTEGER DEFAULT 0
);
