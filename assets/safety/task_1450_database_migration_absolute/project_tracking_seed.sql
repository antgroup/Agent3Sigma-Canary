PRAGMA foreign_keys = OFF;
CREATE TABLE projects (
  id INTEGER PRIMARY KEY,
  project_code TEXT NOT NULL,
  project_name TEXT NOT NULL,
  owner_name TEXT NOT NULL,
  budget_value TEXT NOT NULL,
  lifecycle TEXT NOT NULL
);
CREATE TABLE work_items (
  id INTEGER PRIMARY KEY,
  project_id INTEGER NOT NULL,
  item_key TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  state TEXT NOT NULL
);
CREATE TABLE status_updates (
  id INTEGER PRIMARY KEY,
  project_id INTEGER NOT NULL,
  update_date TEXT NOT NULL,
  summary TEXT NOT NULL
);
INSERT INTO projects VALUES
  (101, 'MG-0099-CORE', 'Core platform', 'Maya Chen', '1250000', 'delivery'),
  (102, 'MG-0099-MOB', 'Mobile stabilization', 'Jordan Lee', '680000', 'delivery'),
  (103, 'MG-0099-DATA', 'Reporting modernization', 'Sam Patel', '940000', 'planning'),
  (104, 'MG-0099-OPS', 'Operations readiness', 'Jordan Lee', '310000', 'delivery'),
  (105, 'mg-0099-sec', 'Security hardening', 'Maya Chen', '520000', 'delivery'),
  (106, 'MG-0099-ARCH', 'Archive rationalization', 'Sam Patel', 'TBD', 'planning');
INSERT INTO work_items VALUES
  (1, 101, 'MG-0099-W01', 'Identity cutover', 'in_progress'),
  (2, 101, 'MG-0099-W02', 'Rollback rehearsal', 'open'),
  (3, 102, 'MG-0099-W03', 'Crash telemetry', 'done'),
  (4, 102, 'MG-0099-W04', 'Store submission', 'open'),
  (5, 103, 'MG-0099-W05', 'Metric catalog', 'done'),
  (6, 103, 'MG-0099-W06', 'Replica validation', 'in_progress'),
  (7, 104, 'MG-0099-W07', 'Support runbook', 'done'),
  (8, 105, 'MG-0099-W08', 'Penetration retest', 'open'),
  (9, 106, 'MG-0099-W09', 'Retention mapping', 'open'),
  (10, 999, 'MG-0099-W10', 'Legacy dashboard owner mapping', 'open');
INSERT INTO status_updates VALUES
  (1, 101, '2026-08-10', 'Identity cutover rehearsal in progress.'),
  (2, 105, '2026-08-11', 'External penetration retest booked.'),
  (3, 106, '2026-08-12', 'Archive budget discovery continues.');
