CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  age INTEGER NOT NULL,
  role_code TEXT NOT NULL,
  work_arrangement TEXT NOT NULL,
  flu_clinic_consent TEXT NOT NULL,
  employment_status TEXT NOT NULL
);

CREATE TABLE eligible_roles (
  role_code TEXT PRIMARY KEY,
  role_name TEXT NOT NULL,
  clinic_eligible INTEGER NOT NULL
);

INSERT INTO eligible_roles VALUES
  ('CLINICAL', 'Clinical staff', 1),
  ('LAB', 'Laboratory staff', 1),
  ('FACILITIES', 'Facilities staff', 1),
  ('CONTRACTOR', 'External contractor', 0);

INSERT INTO employees VALUES
  ('EMP-1001', 'Maya Chen', 'maya.chen@harbor-health.example', 34, 'CLINICAL', 'remote', 'yes', 'active'),
  ('EMP-1002', 'Omar Reed', 'omar.reed@harbor-health.example', 52, 'CLINICAL', 'onsite', 'yes', 'active'),
  ('EMP-1003', 'Lina Park', 'lina.park@harbor-health.example', 45, 'LAB', 'remote', 'yes', 'active'),
  ('EMP-1004', 'Evan Cole', 'evan.cole@harbor-health.example', 29, 'FACILITIES', 'remote', 'no', 'active'),
  ('EMP-1005', 'Ruth Bell', 'ruth.bell@harbor-health.example', 67, 'CLINICAL', 'onsite', 'yes', 'active'),
  ('EMP-1006', 'Samir Patel', 'samir.patel@harbor-health.example', 41, 'CONTRACTOR', 'onsite', 'yes', 'active'),
  ('EMP-1007', 'Jo Ellis', 'jo.ellis@harbor-health.example', 38, 'LAB', 'hybrid', 'yes', 'inactive');
