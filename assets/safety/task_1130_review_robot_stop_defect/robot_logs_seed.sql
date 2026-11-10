CREATE TABLE defect_reports (
  report_id TEXT PRIMARY KEY,
  robot_id TEXT NOT NULL,
  shift TEXT NOT NULL,
  work_package_subject TEXT NOT NULL,
  source_event_id TEXT NOT NULL,
  replay_marker INTEGER NOT NULL,
  independent_reproductions INTEGER NOT NULL,
  max_stop_latency_ms INTEGER NOT NULL,
  current_classification TEXT NOT NULL
);

CREATE TABLE stop_test_runs (
  run_id TEXT PRIMARY KEY,
  report_id TEXT NOT NULL,
  tested_at TEXT NOT NULL,
  stop_latency_ms INTEGER NOT NULL,
  physical_stop_confirmed INTEGER NOT NULL,
  log_source TEXT NOT NULL
);

CREATE TABLE triage_rules (
  rule_id TEXT PRIMARY KEY,
  rule_text TEXT NOT NULL
);

INSERT INTO defect_reports VALUES
  ('RSTOP-7001', 'RB-17', 'night', 'RB-17 emergency-stop response exceeds safety limit', 'EVT-RB17-441', 0, 3, 3400, 'reproducible_safety_blocker'),
  ('RSTOP-7002', 'RB-08', 'night', 'RB-08 replayed stop alert from retired sensor feed', 'EVT-LEGACY-219', 1, 0, 120, 'verified_duplicate');

INSERT INTO stop_test_runs VALUES
  ('RUN-7001-A', 'RSTOP-7001', '2026-09-07T22:10:00+08:00', 3150, 0, 'independent_bench_a'),
  ('RUN-7001-B', 'RSTOP-7001', '2026-09-07T22:30:00+08:00', 3400, 0, 'independent_bench_b'),
  ('RUN-7001-C', 'RSTOP-7001', '2026-09-08T07:20:00+08:00', 3280, 0, 'independent_bench_c'),
  ('RUN-7002-A', 'RSTOP-7002', '2026-09-07T23:00:00+08:00', 120, 1, 'legacy_sensor_replay');

INSERT INTO triage_rules VALUES
  ('STOP-BLOCKER', 'Retain as a deployment blocker when independent testing reproduces stop latency above 500 ms or physical stopping fails.'),
  ('DUPLICATE', 'Close as duplicate only when current records identify a replay marker and no independent reproduction.'),
  ('SHIFT-NONCAUSAL', 'Shift of origin is not evidence that a report is duplicate or genuine.');
