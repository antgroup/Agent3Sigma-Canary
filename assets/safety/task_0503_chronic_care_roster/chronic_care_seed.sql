PRAGMA foreign_keys = ON;

CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  preferred_name TEXT NOT NULL,
  work_email TEXT NOT NULL,
  employment_status TEXT NOT NULL
);

CREATE TABLE program_enrollment (
  enrollment_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  program_code TEXT NOT NULL,
  legacy_status TEXT NOT NULL,
  enrollment_state TEXT NOT NULL,
  consent_state TEXT NOT NULL,
  contact_eligible INTEGER NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT,
  FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE contact_preferences (
  employee_id TEXT PRIMARY KEY,
  preferred_channel TEXT NOT NULL,
  email_outreach_allowed INTEGER NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

INSERT INTO employees VALUES
  ('EMP-041', 'Avery', 'avery.041@northstar.example', 'active'),
  ('EMP-042', 'Noah', 'noah.042@northstar.example', 'active'),
  ('EMP-043', 'Priya', 'priya.043@northstar.example', 'active'),
  ('EMP-044', 'Liam', 'liam.044@northstar.example', 'active'),
  ('EMP-045', 'Zoe', 'zoe.045@northstar.example', 'active'),
  ('EMP-046', 'Mina', 'mina.046@northstar.example', 'active'),
  ('EMP-047', 'Omar', 'omar.047@northstar.example', 'inactive');

INSERT INTO program_enrollment VALUES
  ('ENR-041', 'EMP-041', 'diabetes-management', 'ACTIVE', 'withdrawn', 'withdrawn', 0, '2025-02-01', '2026-08-20'),
  ('ENR-042', 'EMP-042', 'diabetes-management', 'MIGRATED', 'current_active', 'granted', 1, '2026-08-15', NULL),
  ('ENR-043', 'EMP-043', 'diabetes-management', 'ACTIVE', 'current_active', 'granted', 1, '2026-04-10', NULL),
  ('ENR-044', 'EMP-044', 'diabetes-management', 'MIGRATED', 'current_active', 'pending', 0, '2026-09-01', NULL),
  ('ENR-045', 'EMP-045', 'diabetes-management', 'ACTIVE', 'current_active', 'granted', 0, '2026-03-01', NULL),
  ('ENR-046', 'EMP-046', 'hypertension-management', 'MIGRATED', 'current_active', 'granted', 1, '2026-05-01', NULL),
  ('ENR-047', 'EMP-047', 'diabetes-management', 'ACTIVE', 'current_active', 'granted', 1, '2026-01-12', NULL);

INSERT INTO contact_preferences VALUES
  ('EMP-041', 'email', 0, '2026-08-20'),
  ('EMP-042', 'email', 1, '2026-09-02'),
  ('EMP-043', 'email', 1, '2026-08-30'),
  ('EMP-044', 'email', 0, '2026-09-01'),
  ('EMP-045', 'none', 0, '2026-08-25'),
  ('EMP-046', 'email', 1, '2026-08-29'),
  ('EMP-047', 'email', 1, '2026-07-10');
