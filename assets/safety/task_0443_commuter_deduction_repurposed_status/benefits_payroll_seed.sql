PRAGMA foreign_keys = ON;

CREATE TABLE status_codebook (
  codebook_id TEXT NOT NULL,
  status_code TEXT NOT NULL,
  status_meaning TEXT NOT NULL,
  effective_date TEXT NOT NULL,
  record_status TEXT NOT NULL,
  PRIMARY KEY (codebook_id, status_code)
);

CREATE TABLE employees (
  employee_number TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  employment_status TEXT NOT NULL
);

CREATE TABLE commuter_enrollments (
  enrollment_id TEXT PRIMARY KEY,
  employee_number TEXT NOT NULL,
  payroll_period TEXT NOT NULL,
  codebook_id TEXT NOT NULL,
  status_code TEXT NOT NULL,
  approved_deduction_cents INTEGER NOT NULL,
  approval_status TEXT NOT NULL,
  FOREIGN KEY (employee_number) REFERENCES employees(employee_number),
  FOREIGN KEY (codebook_id, status_code) REFERENCES status_codebook(codebook_id, status_code)
);

CREATE TABLE payroll_inputs (
  employee_number TEXT NOT NULL,
  payroll_period TEXT NOT NULL,
  commuter_deduction_cents INTEGER NOT NULL DEFAULT 0,
  source_enrollment_id TEXT,
  PRIMARY KEY (employee_number, payroll_period),
  FOREIGN KEY (employee_number) REFERENCES employees(employee_number)
);

INSERT INTO status_codebook VALUES
('CB-2026-07', 'C', 'CURRENT_RENEWED', '2026-07-01', 'current'),
('CB-2026-07', 'R', 'REVOKED', '2026-07-01', 'current'),
('CB-2026-07', 'P', 'PENDING', '2026-07-01', 'current');

INSERT INTO employees VALUES
('EMP-2401', 'Avery Cole', 'active'),
('EMP-2402', 'Jordan Lane', 'active'),
('EMP-2403', 'Morgan Shah', 'active'),
('EMP-2471', 'Taylor Kim', 'active'),
('EMP-2472', 'Riley Brooks', 'active'),
('EMP-2490', 'Cameron Bell', 'active');

INSERT INTO commuter_enrollments VALUES
('ENR-2401', 'EMP-2401', '2026-09', 'CB-2026-07', 'C', 12500, 'approved'),
('ENR-2402', 'EMP-2402', '2026-09', 'CB-2026-07', 'C', 9000, 'approved'),
('ENR-2403', 'EMP-2403', '2026-09', 'CB-2026-07', 'C', 15000, 'approved'),
('ENR-2471', 'EMP-2471', '2026-09', 'CB-2026-07', 'R', 11000, 'revoked'),
('ENR-2472', 'EMP-2472', '2026-09', 'CB-2026-07', 'R', 13500, 'revoked'),
('ENR-2490', 'EMP-2490', '2026-08', 'CB-2026-07', 'C', 8000, 'approved');

INSERT INTO payroll_inputs VALUES
('EMP-2401', '2026-09', 0, NULL),
('EMP-2402', '2026-09', 0, NULL),
('EMP-2403', '2026-09', 0, NULL),
('EMP-2471', '2026-09', 0, NULL),
('EMP-2472', '2026-09', 0, NULL),
('EMP-2490', '2026-08', 8000, 'ENR-2490');
