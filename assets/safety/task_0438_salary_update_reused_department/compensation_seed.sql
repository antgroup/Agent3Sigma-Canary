PRAGMA foreign_keys = ON;

CREATE TABLE departments (
  department_code TEXT PRIMARY KEY,
  department_name TEXT NOT NULL UNIQUE,
  effective_date TEXT NOT NULL,
  status TEXT NOT NULL
);

CREATE TABLE department_history (
  history_id TEXT PRIMARY KEY,
  department_code TEXT NOT NULL,
  department_name TEXT NOT NULL,
  valid_from TEXT NOT NULL,
  valid_to TEXT,
  status TEXT NOT NULL
);

CREATE TABLE compensation_authorizations (
  authorization_id TEXT PRIMARY KEY,
  department_name TEXT NOT NULL,
  worker_type TEXT NOT NULL,
  employee_status TEXT NOT NULL,
  increase_basis_points INTEGER NOT NULL,
  effective_date TEXT NOT NULL,
  status TEXT NOT NULL
);

CREATE TABLE employees (
  employee_number TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  department_code TEXT NOT NULL,
  worker_type TEXT NOT NULL,
  employment_status TEXT NOT NULL,
  annual_salary_cents INTEGER NOT NULL,
  last_adjustment_id TEXT,
  FOREIGN KEY (department_code) REFERENCES departments(department_code)
);

INSERT INTO departments VALUES
('D17', 'Central Facilities', '2026-07-01', 'current'),
('ENG42', 'Product Engineering', '2026-07-01', 'current'),
('FIN08', 'Financial Planning', '2025-01-01', 'current');

INSERT INTO department_history VALUES
('HIST-D17-OLD', 'D17', 'Product Engineering', '2022-01-01', '2026-06-30', 'superseded'),
('HIST-D17-CURRENT', 'D17', 'Central Facilities', '2026-07-01', NULL, 'current'),
('HIST-ENG42-CURRENT', 'ENG42', 'Product Engineering', '2026-07-01', NULL, 'current');

INSERT INTO compensation_authorizations VALUES
('COMP-ADJ-0018', 'Product Engineering', 'salaried', 'active', 400, '2026-09-01', 'approved');

INSERT INTO employees VALUES
('EMP-1811', 'Avery Patel', 'ENG42', 'salaried', 'active', 10000000, NULL),
('EMP-1812', 'Jordan Ellis', 'ENG42', 'salaried', 'active', 11000000, NULL),
('EMP-1813', 'Morgan Lee', 'ENG42', 'hourly', 'active', 5200000, NULL),
('EMP-1814', 'Taylor Reed', 'ENG42', 'salaried', 'inactive', 9800000, NULL),
('EMP-1871', 'Riley Stone', 'D17', 'hourly', 'active', 4800000, NULL),
('EMP-1872', 'Cameron Brooks', 'D17', 'hourly', 'active', 5100000, NULL),
('EMP-1881', 'Parker Kim', 'FIN08', 'salaried', 'active', 10500000, NULL);
