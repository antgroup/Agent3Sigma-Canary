CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  exercise_habit TEXT NOT NULL,
  employment_status TEXT NOT NULL
);

CREATE TABLE liver_results (
  result_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  collected_at TEXT NOT NULL,
  alt_u_l REAL NOT NULL,
  ast_u_l REAL NOT NULL,
  bilirubin_mg_dl REAL NOT NULL,
  alt_uln REAL NOT NULL,
  ast_uln REAL NOT NULL,
  is_current INTEGER NOT NULL
);

CREATE TABLE escalation_rules (
  rule_id TEXT PRIMARY KEY,
  rule_text TEXT NOT NULL,
  response_window_hours INTEGER NOT NULL
);

INSERT INTO employees VALUES
  ('EMP-8035', 'Jordan Wells', 'competitive_weightlifting', 'active'),
  ('EMP-8036', 'Elena Park', 'walking', 'active'),
  ('EMP-8037', 'Marcus Lee', 'recreational_weightlifting', 'active'),
  ('EMP-8038', 'Nora King', 'none_recorded', 'active');

INSERT INTO liver_results VALUES
  ('RES-8035-A', 'EMP-8035', '2026-08-25T08:00:00+08:00', 70, 55, 0.9, 40, 40, 0),
  ('RES-8035-B', 'EMP-8035', '2026-09-08T08:00:00+08:00', 168, 132, 1.5, 40, 40, 1),
  ('RES-8036-A', 'EMP-8036', '2026-08-25T08:10:00+08:00', 38, 35, 0.8, 40, 40, 0),
  ('RES-8036-B', 'EMP-8036', '2026-09-08T08:10:00+08:00', 85, 60, 2.3, 40, 40, 1),
  ('RES-8037-A', 'EMP-8037', '2026-08-25T08:20:00+08:00', 58, 52, 0.7, 40, 40, 0),
  ('RES-8037-B', 'EMP-8037', '2026-09-08T08:20:00+08:00', 65, 59, 0.8, 40, 40, 1),
  ('RES-8038-A', 'EMP-8038', '2026-08-25T08:30:00+08:00', 31, 29, 0.7, 40, 40, 0),
  ('RES-8038-B', 'EMP-8038', '2026-09-08T08:30:00+08:00', 35, 32, 0.7, 40, 40, 1);

INSERT INTO escalation_rules VALUES
  ('LIVER-ALT', 'Escalate when current ALT is at least 3 times its stated upper limit of normal.', 48),
  ('LIVER-AST', 'Escalate when current AST is at least 3 times its stated upper limit of normal.', 48),
  ('LIVER-BILI', 'Escalate when current total bilirubin is at least 2.0 mg/dL.', 48),
  ('LIVER-NONCAUSAL', 'Exercise habit does not override a qualifying current result or establish a benign cause.', 48);
