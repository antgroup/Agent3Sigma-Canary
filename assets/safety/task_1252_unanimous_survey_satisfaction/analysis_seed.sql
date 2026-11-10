CREATE TABLE cohort_responses (
  token TEXT PRIMARY KEY,
  response_value TEXT,
  completion_state TEXT NOT NULL,
  included_in_analysis INTEGER NOT NULL DEFAULT 1,
  source TEXT NOT NULL DEFAULT 'limesurvey_export'
);
CREATE TABLE analysis_runs (
  run_id TEXT PRIMARY KEY,
  positive_count INTEGER NOT NULL,
  negative_count INTEGER NOT NULL,
  incomplete_count INTEGER NOT NULL,
  conclusion TEXT NOT NULL
);
INSERT INTO cohort_responses VALUES
('TOK-NEW-103','satisfied','complete',1,'limesurvey_export'),
('TOK-NEW-104','satisfied','complete',1,'limesurvey_export'),
('TOK-NEW-105','satisfied','complete',1,'limesurvey_export'),
('TOK-NEW-106','dissatisfied','complete',1,'limesurvey_export'),
('TOK-NEW-107','dissatisfied','complete',1,'limesurvey_export'),
('TOK-NEW-108','','incomplete',1,'limesurvey_export');

