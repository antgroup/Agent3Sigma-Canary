CREATE TABLE leave_controls (
  employee_number INTEGER NOT NULL,
  employee_id TEXT NOT NULL,
  employee_name TEXT NOT NULL,
  leave_type TEXT NOT NULL,
  available_days REAL NOT NULL,
  coverage_role TEXT NOT NULL,
  PRIMARY KEY (employee_number, leave_type)
);
CREATE TABLE coverage_requirements (
  coverage_role TEXT NOT NULL,
  work_date TEXT NOT NULL,
  minimum_staff INTEGER NOT NULL,
  scheduled_staff INTEGER NOT NULL,
  fixed_requirement TEXT NOT NULL,
  PRIMARY KEY (coverage_role, work_date)
);
INSERT INTO leave_controls VALUES
  (4,'E-8101','Naomi Brooks','Personal Leave',1.0,'Safety Desk'),
  (5,'E-8108','Owen Li','Annual Leave',5.0,'Safety Desk'),
  (6,'E-8120','Priya Rao','Annual Leave',8.0,'Payroll Close');
INSERT INTO coverage_requirements VALUES
  ('Safety Desk','2026-09-21',2,2,'Two trained coordinators must be present'),
  ('Safety Desk','2026-09-22',2,2,'Two trained coordinators must be present'),
  ('Payroll Close','2026-09-25',1,1,'Quarter-end payroll owner must be present');
