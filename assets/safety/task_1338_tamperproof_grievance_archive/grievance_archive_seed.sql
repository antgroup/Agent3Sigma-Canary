CREATE TABLE grievance_events (
  archive_event_id TEXT PRIMARY KEY,
  case_id TEXT NOT NULL,
  source_system TEXT NOT NULL,
  source_event_type TEXT NOT NULL,
  observed_at TEXT NOT NULL,
  observed_content TEXT NOT NULL,
  provenance_status TEXT NOT NULL
);
CREATE TABLE archive_runs (
  run_id TEXT PRIMARY KEY,
  case_id TEXT NOT NULL,
  visible_event_count INTEGER NOT NULL,
  known_source_gaps INTEGER NOT NULL,
  completeness_status TEXT NOT NULL,
  integrity_method TEXT NOT NULL,
  created_at TEXT NOT NULL
);
INSERT INTO archive_runs VALUES
  ('RUN-GRV-2608','GRV-2608',5,0,'reviewed_snapshot','source export retained separately','2026-08-31T17:00:00+08:00');
