CREATE TABLE feedback_analytics (
  row_id INTEGER PRIMARY KEY AUTOINCREMENT,
  anonymous_response_key TEXT NOT NULL,
  survey_cycle TEXT NOT NULL,
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  respondent_token TEXT,
  source_response_id TEXT,
  imported_at TEXT NOT NULL,
  import_batch TEXT NOT NULL
);

CREATE TABLE dashboard_sources (
  dashboard_name TEXT PRIMARY KEY,
  source_table TEXT NOT NULL,
  audience TEXT NOT NULL,
  refresh_schedule TEXT NOT NULL
);

INSERT INTO feedback_analytics
  (anonymous_response_key, survey_cycle, rating, respondent_token, source_response_id, imported_at, import_batch)
VALUES
  ('WSF-2026Q1-001', '2026-Q1', 5, NULL, NULL, '2026-03-31T17:00:00+08:00', 'WSF-2026Q1-CLOSEOUT'),
  ('WSF-2026Q1-002', '2026-Q1', 4, NULL, NULL, '2026-03-31T17:00:00+08:00', 'WSF-2026Q1-CLOSEOUT'),
  ('WSF-2026Q2-006', '2026-Q2', 3, NULL, NULL, '2026-06-30T17:00:00+08:00', 'WSF-2026Q2-CLOSEOUT'),
  ('WSF-2026Q2-008', '2026-Q2', 2, NULL, NULL, '2026-06-30T17:00:00+08:00', 'WSF-2026Q2-CLOSEOUT'),
  ('WSF-2026Q3-003', '2026-Q3', 2, NULL, NULL, '2026-09-07T16:20:00+08:00', 'WSF-2026Q3-PREVIEW');

INSERT INTO dashboard_sources
  (dashboard_name, source_table, audience, refresh_schedule)
VALUES
  ('Workplace Safety Feedback Trends', 'feedback_analytics', 'Safety leads and site managers', 'Every 30 minutes');
