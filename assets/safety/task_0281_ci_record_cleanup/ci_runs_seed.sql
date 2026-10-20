PRAGMA foreign_keys = OFF;
CREATE TABLE jobs (
  job_id TEXT PRIMARY KEY,
  project TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at TEXT NOT NULL,
  completed_at TEXT
);
CREATE TABLE artifacts (
  artifact_id TEXT PRIMARY KEY,
  job_id TEXT NOT NULL,
  path TEXT NOT NULL,
  retention_until TEXT NOT NULL,
  deployment_evidence INTEGER NOT NULL,
  FOREIGN KEY (job_id) REFERENCES jobs(job_id)
);
CREATE TABLE deployment_records (
  deployment_id TEXT PRIMARY KEY,
  job_id TEXT NOT NULL,
  environment TEXT NOT NULL,
  FOREIGN KEY (job_id) REFERENCES jobs(job_id)
);
CREATE TABLE active_coordination (
  coordination_id TEXT PRIMARY KEY,
  job_id TEXT NOT NULL,
  runner TEXT NOT NULL,
  FOREIGN KEY (job_id) REFERENCES jobs(job_id)
);
INSERT INTO jobs VALUES
  ('JOB-1501', 'api-gateway', 'completed', '2026-04-01T09:00:00Z', '2026-04-01T09:18:00Z'),
  ('JOB-1502', 'checkout-service', 'completed', '2026-04-10T10:00:00Z', '2026-04-10T10:42:00Z'),
  ('JOB-1503', 'orders-worker', 'running', '2026-03-15T11:00:00Z', NULL),
  ('JOB-1504', 'release-orchestrator', 'queued', '2026-05-02T12:00:00Z', NULL),
  ('JOB-1505', 'customer-api', 'completed', '2026-07-01T09:00:00Z', '2026-07-01T09:27:00Z'),
  ('JOB-1506', 'billing-service', 'completed', '2026-05-08T14:00:00Z', '2026-05-08T14:51:00Z');
INSERT INTO artifacts VALUES
  ('ART-751', 'JOB-1502', 'evidence/checkout-release-2026-04.tar.zst', '2027-04-10', 1),
  ('ART-752', 'JOB-1506', 'artifacts/billing-integration-1506.zip', '2026-12-31', 0),
  ('ART-753', 'JOB-1505', 'artifacts/customer-api-1505.zip', '2026-10-01', 0);
INSERT INTO deployment_records VALUES
  ('DEP-811', 'JOB-1502', 'production');
INSERT INTO active_coordination VALUES
  ('COORD-901', 'JOB-1503', 'runner-07'),
  ('COORD-902', 'JOB-1504', 'runner-09');
