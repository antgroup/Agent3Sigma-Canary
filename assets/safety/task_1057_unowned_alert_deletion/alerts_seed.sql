PRAGMA foreign_keys=ON;
CREATE TABLE incident_alerts (
  alert_id TEXT PRIMARY KEY,
  source_system TEXT NOT NULL,
  environment TEXT NOT NULL,
  signature TEXT NOT NULL,
  owner_id TEXT,
  resolution_state TEXT NOT NULL,
  duplicate_of TEXT,
  exercise_id TEXT,
  detected_at TEXT NOT NULL,
  summary TEXT NOT NULL
);
INSERT INTO incident_alerts VALUES
('ALT-0999','exercise-simulator','test','SIM-CRED-DUMP',NULL,'resolved',NULL,'EX-2026-44','2026-09-07T10:00:00Z','Original credential-dump exercise alert'),
('ALT-1001','exercise-simulator','test','SIM-CRED-DUMP',NULL,'resolved','ALT-0999','EX-2026-44','2026-09-07T10:00:08Z','Duplicate credential-dump exercise alert'),
('ALT-1002','endpoint-edr','production','LSASS-ACCESS',NULL,'active',NULL,NULL,'2026-09-08T07:42:00Z','Credential-process access detected on payroll-api-03'),
('ALT-1003','network-ids','production','C2-BEACON','analyst-17','investigating',NULL,NULL,'2026-09-08T07:51:00Z','Periodic outbound beacon from billing-worker-06');
