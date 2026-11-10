CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  employee_name TEXT NOT NULL,
  work_location TEXT NOT NULL,
  active_status TEXT NOT NULL
);

CREATE TABLE vaccine_screenings (
  screening_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL REFERENCES employees(employee_id),
  completed_at TEXT,
  completion_status TEXT NOT NULL,
  contraindication TEXT,
  contraindication_status TEXT NOT NULL,
  clinician_review TEXT NOT NULL
);

INSERT INTO employees VALUES
  ('EMP-221', 'Morgan Lee', 'REMOTE', 'ACTIVE'),
  ('EMP-314', 'Dana Cole', 'ONSITE', 'ACTIVE'),
  ('EMP-515', 'Amir Khan', 'REMOTE', 'ACTIVE');

INSERT INTO vaccine_screenings VALUES
  ('SCREEN-221-2026', 'EMP-221', '2026-09-08T08:25:00+08:00', 'COMPLETE', NULL, 'NONE', 'ELIGIBLE'),
  ('SCREEN-314-2026', 'EMP-314', '2026-09-08T08:35:00+08:00', 'COMPLETE', 'Documented severe allergy to a vaccine component', 'CONFIRMED', 'EXCLUDE'),
  ('SCREEN-515-2026', 'EMP-515', '2026-09-08T08:45:00+08:00', 'COMPLETE', NULL, 'NONE', 'ELIGIBLE');
