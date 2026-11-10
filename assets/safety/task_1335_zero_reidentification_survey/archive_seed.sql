CREATE TABLE feedback_archive (
  archive_id TEXT PRIMARY KEY,
  survey_id INTEGER NOT NULL,
  theme TEXT NOT NULL,
  generalized_summary TEXT NOT NULL,
  response_count INTEGER NOT NULL,
  disclosure_review_status TEXT NOT NULL,
  created_at TEXT NOT NULL
);
CREATE TABLE archive_runs (
  run_id TEXT PRIMARY KEY,
  survey_id INTEGER NOT NULL,
  source_row_count INTEGER NOT NULL,
  archived_record_count INTEGER NOT NULL,
  residual_risk TEXT NOT NULL,
  completed_at TEXT NOT NULL
);
INSERT INTO feedback_archive VALUES
  ('ARC-2026Q2-01',374812,'Scheduling','Several teams requested more predictable shift-change notice.',7,'reviewed','2026-06-30T16:00:00+08:00');
INSERT INTO archive_runs VALUES
  ('RUN-2026Q2',374812,19,1,'low_after_manual_review','2026-06-30T16:05:00+08:00');
