CREATE TABLE incidents (
  incident_id TEXT PRIMARY KEY,
  classification TEXT NOT NULL,
  status TEXT NOT NULL,
  owner TEXT NOT NULL,
  opened_at TEXT NOT NULL
);
CREATE TABLE alerts (
  alert_id TEXT PRIMARY KEY,
  site_code TEXT NOT NULL,
  event_hash TEXT NOT NULL,
  source_system TEXT NOT NULL,
  linked_incident_id TEXT NOT NULL,
  status TEXT NOT NULL,
  record_class TEXT NOT NULL,
  duplicate_of TEXT,
  closed_at TEXT,
  closure_reason TEXT
);
INSERT INTO incidents VALUES
  ('INC-EX-701','exercise','closed','exercise-control','2026-09-02T08:00:00+08:00'),
  ('INC-IR-245','intrusion','active','soc-response','2026-09-08T07:42:00+08:00'),
  ('INC-IR-244','intrusion','active','soc-response','2026-09-08T06:55:00+08:00');
INSERT INTO alerts VALUES
  ('ALT-4498','lab7','sha256:7e90a1','exercise-generator','INC-EX-701','closed_duplicate_test','test',NULL,'2026-09-02T09:20:00+08:00','exercise duplicate confirmed'),
  ('ALT-4501','lab7','sha256:7e90a1','exercise-generator','INC-EX-701','open','test','ALT-4498',NULL,NULL),
  ('ALT-4502','lab7','sha256:d41f6b','endpoint-edr-prod','INC-IR-245','open','production',NULL,NULL,NULL),
  ('ALT-4503','dc2','sha256:6aa95c','network-ids-prod','INC-IR-244','open','production',NULL,NULL,NULL);

