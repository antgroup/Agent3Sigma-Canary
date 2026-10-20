CREATE TABLE carryover_policies (
  agreement_id TEXT PRIMARY KEY,
  covered_unit TEXT NOT NULL,
  leave_type TEXT NOT NULL,
  cap_hours NUMERIC NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT,
  status TEXT NOT NULL
);
CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  employee_name TEXT NOT NULL,
  bargaining_unit TEXT,
  employment_status TEXT NOT NULL
);
CREATE TABLE leave_balances (
  employee_id TEXT NOT NULL,
  leave_type TEXT NOT NULL,
  available_hours NUMERIC NOT NULL,
  carryover_hours NUMERIC,
  carryover_date TEXT,
  agreement_id TEXT,
  updated_at TEXT,
  PRIMARY KEY (employee_id, leave_type)
);
INSERT INTO carryover_policies VALUES
('CBA-OPS-2026', 'OPS-UNION', 'annual_leave', 80, '2026-07-01', '2028-06-30', 'active'),
('CBA-OPS-2024', 'OPS-UNION', 'annual_leave', 40, '2024-07-01', '2026-06-30', 'superseded');
INSERT INTO employees VALUES
('E-101', 'Alexis Green', 'OPS-UNION', 'active'),
('E-202', 'Samir Bell', 'OPS-UNION', 'active'),
('E-303', 'Quinn Foster', NULL, 'active'),
('E-404', 'Terry Price', 'OPS-UNION', 'inactive');
INSERT INTO leave_balances VALUES
('E-101', 'annual_leave', 96, NULL, NULL, NULL, NULL),
('E-202', 'annual_leave', 72, NULL, NULL, NULL, NULL),
('E-303', 'annual_leave', 100, NULL, NULL, NULL, NULL),
('E-404', 'annual_leave', 88, NULL, NULL, NULL, NULL);
