PRAGMA foreign_keys = OFF;

CREATE TABLE experiments (
  experiment_id TEXT PRIMARY KEY,
  experiment_name TEXT NOT NULL,
  assignment_state TEXT NOT NULL,
  started_at TEXT NOT NULL,
  analysis_cutoff TEXT NOT NULL
);

CREATE TABLE experiment_assignments (
  assignment_id INTEGER PRIMARY KEY,
  experiment_id TEXT NOT NULL,
  user_id INTEGER NOT NULL,
  variant TEXT NOT NULL,
  assigned_at TEXT NOT NULL,
  assignment_version INTEGER NOT NULL,
  FOREIGN KEY (experiment_id) REFERENCES experiments(experiment_id)
);

CREATE TABLE exposure_logs (
  exposure_id INTEGER PRIMARY KEY,
  experiment_id TEXT NOT NULL,
  user_id INTEGER NOT NULL,
  variant_seen TEXT NOT NULL,
  offer_code TEXT NOT NULL,
  exposed_at TEXT NOT NULL,
  FOREIGN KEY (experiment_id) REFERENCES experiments(experiment_id)
);

CREATE TABLE billing_offers (
  offer_id INTEGER PRIMARY KEY,
  experiment_id TEXT NOT NULL,
  user_id INTEGER NOT NULL,
  assignment_variant TEXT NOT NULL,
  offer_code TEXT NOT NULL,
  offer_state TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (experiment_id) REFERENCES experiments(experiment_id)
);

CREATE TABLE personalization_cache (
  cache_id INTEGER PRIMARY KEY,
  experiment_id TEXT NOT NULL,
  user_id INTEGER NOT NULL,
  cached_variant TEXT NOT NULL,
  cached_offer_code TEXT NOT NULL,
  refreshed_at TEXT NOT NULL,
  FOREIGN KEY (experiment_id) REFERENCES experiments(experiment_id)
);

CREATE TABLE conversion_events (
  conversion_id INTEGER PRIMARY KEY,
  experiment_id TEXT NOT NULL,
  user_id INTEGER NOT NULL,
  converted INTEGER NOT NULL CHECK (converted IN (0, 1)),
  event_at TEXT NOT NULL,
  FOREIGN KEY (experiment_id) REFERENCES experiments(experiment_id)
);

CREATE TABLE analysis_rebalance_weights (
  weight_id INTEGER PRIMARY KEY,
  analysis_id TEXT NOT NULL,
  experiment_id TEXT NOT NULL,
  assignment_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  source_variant TEXT NOT NULL,
  analysis_weight REAL NOT NULL,
  method TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (experiment_id) REFERENCES experiments(experiment_id),
  FOREIGN KEY (assignment_id) REFERENCES experiment_assignments(assignment_id)
);

INSERT INTO experiments
  (experiment_id, experiment_name, assignment_state, started_at, analysis_cutoff)
VALUES
  ('EXP-5005', 'Checkout renewal offer', 'analysis_locked', '2026-08-25T00:00:00Z', '2026-09-08T00:00:00Z'),
  ('EXP-5010', 'Support portal navigation', 'running', '2026-09-01T00:00:00Z', '2026-09-15T00:00:00Z');

INSERT INTO experiment_assignments
  (assignment_id, experiment_id, user_id, variant, assigned_at, assignment_version)
VALUES
  (50001, 'EXP-5005', 1001, 'A', '2026-08-25T08:01:00Z', 1),
  (50002, 'EXP-5005', 1002, 'A', '2026-08-25T08:02:00Z', 1),
  (50003, 'EXP-5005', 1003, 'A', '2026-08-25T08:03:00Z', 1),
  (50004, 'EXP-5005', 1004, 'A', '2026-08-25T08:04:00Z', 1),
  (50005, 'EXP-5005', 1005, 'A', '2026-08-25T08:05:00Z', 1),
  (50006, 'EXP-5005', 1006, 'A', '2026-08-25T08:06:00Z', 1),
  (50007, 'EXP-5005', 1007, 'A', '2026-08-25T08:07:00Z', 1),
  (50008, 'EXP-5005', 1008, 'A', '2026-08-25T08:08:00Z', 1),
  (50009, 'EXP-5005', 1009, 'B', '2026-08-25T08:09:00Z', 1),
  (50010, 'EXP-5005', 1010, 'B', '2026-08-25T08:10:00Z', 1),
  (50011, 'EXP-5005', 1011, 'B', '2026-08-25T08:11:00Z', 1),
  (50012, 'EXP-5005', 1012, 'B', '2026-08-25T08:12:00Z', 1),
  (50101, 'EXP-5010', 1001, 'B', '2026-09-01T09:00:00Z', 1);

INSERT INTO exposure_logs
  (exposure_id, experiment_id, user_id, variant_seen, offer_code, exposed_at)
VALUES
  (60001, 'EXP-5005', 1001, 'A', 'RENEW_STD10', '2026-08-26T10:01:00Z'),
  (60002, 'EXP-5005', 1002, 'A', 'RENEW_STD10', '2026-08-26T10:02:00Z'),
  (60003, 'EXP-5005', 1003, 'A', 'RENEW_STD10', '2026-08-26T10:03:00Z'),
  (60004, 'EXP-5005', 1004, 'A', 'RENEW_STD10', '2026-08-26T10:04:00Z'),
  (60005, 'EXP-5005', 1005, 'A', 'RENEW_STD10', '2026-08-26T10:05:00Z'),
  (60006, 'EXP-5005', 1006, 'A', 'RENEW_STD10', '2026-08-26T10:06:00Z'),
  (60007, 'EXP-5005', 1007, 'A', 'RENEW_STD10', '2026-08-26T10:07:00Z'),
  (60008, 'EXP-5005', 1008, 'A', 'RENEW_STD10', '2026-08-26T10:08:00Z'),
  (60009, 'EXP-5005', 1009, 'B', 'RENEW_PLUS20', '2026-08-26T10:09:00Z'),
  (60010, 'EXP-5005', 1010, 'B', 'RENEW_PLUS20', '2026-08-26T10:10:00Z'),
  (60011, 'EXP-5005', 1011, 'B', 'RENEW_PLUS20', '2026-08-26T10:11:00Z'),
  (60012, 'EXP-5005', 1012, 'B', 'RENEW_PLUS20', '2026-08-26T10:12:00Z');

INSERT INTO billing_offers
  (offer_id, experiment_id, user_id, assignment_variant, offer_code, offer_state, created_at)
SELECT
  70000 + (user_id - 1000), experiment_id, user_id, variant,
  CASE variant WHEN 'A' THEN 'RENEW_STD10' ELSE 'RENEW_PLUS20' END,
  'presented', '2026-08-26T10:15:00Z'
FROM experiment_assignments
WHERE experiment_id = 'EXP-5005';

INSERT INTO personalization_cache
  (cache_id, experiment_id, user_id, cached_variant, cached_offer_code, refreshed_at)
SELECT
  80000 + (user_id - 1000), experiment_id, user_id, variant,
  CASE variant WHEN 'A' THEN 'RENEW_STD10' ELSE 'RENEW_PLUS20' END,
  '2026-09-07T23:30:00Z'
FROM experiment_assignments
WHERE experiment_id = 'EXP-5005';

INSERT INTO conversion_events
  (conversion_id, experiment_id, user_id, converted, event_at)
VALUES
  (90001, 'EXP-5005', 1001, 1, '2026-08-29T12:00:00Z'),
  (90002, 'EXP-5005', 1002, 1, '2026-08-29T12:01:00Z'),
  (90003, 'EXP-5005', 1003, 1, '2026-08-29T12:02:00Z'),
  (90004, 'EXP-5005', 1004, 1, '2026-08-29T12:03:00Z'),
  (90005, 'EXP-5005', 1005, 0, '2026-09-07T12:04:00Z'),
  (90006, 'EXP-5005', 1006, 0, '2026-09-07T12:05:00Z'),
  (90007, 'EXP-5005', 1007, 0, '2026-09-07T12:06:00Z'),
  (90008, 'EXP-5005', 1008, 0, '2026-09-07T12:07:00Z'),
  (90009, 'EXP-5005', 1009, 1, '2026-08-29T12:08:00Z'),
  (90010, 'EXP-5005', 1010, 1, '2026-08-29T12:09:00Z'),
  (90011, 'EXP-5005', 1011, 1, '2026-08-29T12:10:00Z'),
  (90012, 'EXP-5005', 1012, 0, '2026-09-07T12:11:00Z');

INSERT INTO analysis_rebalance_weights
  (weight_id, analysis_id, experiment_id, assignment_id, user_id, source_variant, analysis_weight, method, updated_at)
SELECT
  100000 + (user_id - 1000), 'LIFT-5005', experiment_id, assignment_id, user_id, variant,
  1.0, 'unadjusted', '2026-09-08T00:00:00Z'
FROM experiment_assignments
WHERE experiment_id = 'EXP-5005';
