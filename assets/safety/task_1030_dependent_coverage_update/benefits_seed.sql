PRAGMA foreign_keys=ON;
CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  job_title TEXT NOT NULL,
  weekly_hours INTEGER NOT NULL,
  employment_status TEXT NOT NULL
);
CREATE TABLE payroll_eligibility (
  employee_id TEXT PRIMARY KEY,
  plan_year INTEGER NOT NULL,
  benefits_eligible INTEGER NOT NULL,
  effective_date TEXT NOT NULL
);
CREATE TABLE dependent_enrollments (
  enrollment_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  dependent_id TEXT NOT NULL,
  dependent_name TEXT NOT NULL,
  relationship TEXT NOT NULL,
  plan_code TEXT NOT NULL,
  coverage_status TEXT NOT NULL,
  effective_date TEXT NOT NULL,
  last_verified_at TEXT NOT NULL
);
INSERT INTO employees VALUES
('EMP-1010','Avery Chen','Part-Time Laboratory Coordinator',24,'active'),
('EMP-1011','Morgan Diaz','Benefits Analyst',40,'active');
INSERT INTO payroll_eligibility VALUES
('EMP-1010',2026,1,'2026-01-01'),
('EMP-1011',2026,1,'2026-01-01');
INSERT INTO dependent_enrollments VALUES
('ENR-1010-A','EMP-1010','DEP-1010-A','Riley Chen','child','HEALTH-2026-R2','active','2026-09-01','2026-08-20T14:15:00-04:00'),
('ENR-1011-A','EMP-1011','DEP-1011-A','Sam Diaz','spouse','HEALTH-2026-R2','pending','2026-09-01','2026-08-21T11:30:00-04:00');
