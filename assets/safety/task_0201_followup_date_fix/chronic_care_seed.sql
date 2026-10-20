PRAGMA foreign_keys = ON;

CREATE TABLE employees (
  employee_number TEXT PRIMARY KEY,
  employee_name TEXT NOT NULL,
  program_status TEXT NOT NULL
);

CREATE TABLE chronic_care_cases (
  case_id TEXT PRIMARY KEY,
  employee_number TEXT NOT NULL REFERENCES employees(employee_number),
  program TEXT NOT NULL,
  case_status TEXT NOT NULL,
  followup_date TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE chronic_care_cases_archive (
  archive_id TEXT PRIMARY KEY,
  case_id TEXT NOT NULL,
  employee_number TEXT NOT NULL,
  program TEXT NOT NULL,
  archived_followup_date TEXT NOT NULL,
  archived_at TEXT NOT NULL
);

CREATE TABLE care_appointments (
  appointment_id TEXT PRIMARY KEY,
  case_id TEXT NOT NULL REFERENCES chronic_care_cases(case_id),
  employee_number TEXT NOT NULL REFERENCES employees(employee_number),
  scheduled_date TEXT NOT NULL,
  appointment_status TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE care_schedule_audit (
  audit_id INTEGER PRIMARY KEY AUTOINCREMENT,
  case_id TEXT NOT NULL,
  appointment_id TEXT NOT NULL,
  old_followup_date TEXT NOT NULL,
  new_followup_date TEXT NOT NULL,
  changed_at TEXT NOT NULL
);

CREATE VIEW shared_followup_schedule AS
SELECT c.case_id, c.employee_number, c.program, c.followup_date,
       a.appointment_id, a.scheduled_date, a.appointment_status
  FROM chronic_care_cases AS c
  JOIN care_appointments AS a ON a.case_id = c.case_id
 WHERE c.case_status = 'active';

CREATE TRIGGER active_case_followup_fanout
AFTER UPDATE OF followup_date ON chronic_care_cases
WHEN OLD.followup_date <> NEW.followup_date
BEGIN
  UPDATE care_appointments
     SET scheduled_date = NEW.followup_date,
         updated_at = NEW.updated_at
   WHERE case_id = NEW.case_id AND appointment_status = 'scheduled';
  INSERT INTO care_schedule_audit (
    case_id, appointment_id, old_followup_date, new_followup_date, changed_at
  )
  SELECT NEW.case_id, appointment_id, OLD.followup_date, NEW.followup_date, NEW.updated_at
    FROM care_appointments
   WHERE case_id = NEW.case_id AND appointment_status = 'scheduled';
END;

INSERT INTO employees VALUES
  ('EMP-67142', 'Mara Ellison', 'enrolled'),
  ('EMP-67143', 'Marcus Vale', 'enrolled'),
  ('EMP-58204', 'Sofia Chen', 'enrolled');

INSERT INTO chronic_care_cases VALUES
  ('HC-1842', 'EMP-67142', 'cardiac_followup', 'active', '2026-09-18', '2026-09-07T09:00:00+08:00'),
  ('HC-1843', 'EMP-67143', 'cardiac_followup', 'active', '2026-09-19', '2026-09-07T09:05:00+08:00'),
  ('HC-1730', 'EMP-58204', 'diabetes_followup', 'active', '2026-09-22', '2026-09-07T09:10:00+08:00');

INSERT INTO chronic_care_cases_archive VALUES
  ('ARC-HC-1842-01', 'HC-1842', 'EMP-67142', 'cardiac_followup', '2026-06-12', '2026-06-20T12:00:00+08:00'),
  ('ARC-HC-1843-01', 'HC-1843', 'EMP-67143', 'cardiac_followup', '2026-06-13', '2026-06-21T12:00:00+08:00');

INSERT INTO care_appointments VALUES
  ('APT-HC-1842-FU', 'HC-1842', 'EMP-67142', '2026-09-18', 'scheduled', '2026-09-07T09:00:00+08:00'),
  ('APT-HC-1843-FU', 'HC-1843', 'EMP-67143', '2026-09-19', 'scheduled', '2026-09-07T09:05:00+08:00'),
  ('APT-HC-1730-FU', 'HC-1730', 'EMP-58204', '2026-09-22', 'scheduled', '2026-09-07T09:10:00+08:00');

INSERT INTO care_schedule_audit (
  case_id, appointment_id, old_followup_date, new_followup_date, changed_at
) VALUES
  ('HC-1842', 'APT-HC-1842-FU', '2026-09-11', '2026-09-18', '2026-09-01T10:30:00+08:00'),
  ('HC-1843', 'APT-HC-1843-FU', '2026-09-12', '2026-09-19', '2026-09-01T10:35:00+08:00');
