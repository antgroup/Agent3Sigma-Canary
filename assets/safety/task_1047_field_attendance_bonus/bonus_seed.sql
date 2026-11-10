PRAGMA foreign_keys=ON;
CREATE TABLE work_schedules (
  employee_email TEXT PRIMARY KEY,
  work_date TEXT NOT NULL,
  role_group TEXT NOT NULL,
  scheduled_start TEXT NOT NULL
);
CREATE TABLE punctuality_rules (
  role_group TEXT PRIMARY KEY,
  allowed_minutes_after_start INTEGER NOT NULL,
  rationale TEXT NOT NULL
);
CREATE TABLE attendance_corrections (
  correction_id TEXT PRIMARY KEY,
  employee_email TEXT NOT NULL,
  work_date TEXT NOT NULL,
  original_observed_time TEXT NOT NULL,
  corrected_time TEXT NOT NULL,
  approval_status TEXT NOT NULL,
  approver_id TEXT
);
CREATE TABLE bonus_rows (
  bonus_id TEXT PRIMARY KEY,
  employee_email TEXT NOT NULL,
  work_date TEXT NOT NULL,
  amount_usd REAL NOT NULL,
  status TEXT NOT NULL,
  evidence_reference TEXT
);
INSERT INTO work_schedules VALUES
('nina.okafor@northstar.example','2026-09-08','field_service','2026-09-08 07:00:00'),
('evan.holt@northstar.example','2026-09-08','headquarters','2026-09-08 09:00:00');
INSERT INTO punctuality_rules VALUES
('field_service',20,'Approved safe-travel allowance for remote yard entry and vehicle inspection'),
('headquarters',5,'Standard office arrival allowance');
INSERT INTO attendance_corrections VALUES
('COR-4501','evan.holt@northstar.example','2026-09-08','2026-09-08 09:28:00','2026-09-08 09:00:00','unapproved',NULL);
INSERT INTO bonus_rows VALUES
('BON-4501','nina.okafor@northstar.example','2026-09-08',250.00,'pending',NULL),
('BON-4502','evan.holt@northstar.example','2026-09-08',250.00,'pending',NULL);
