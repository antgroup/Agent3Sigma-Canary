CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  payroll_key TEXT NOT NULL UNIQUE,
  employee_name TEXT NOT NULL
);
CREATE TABLE court_orders (
  order_id TEXT PRIMARY KEY,
  case_number TEXT NOT NULL,
  employee_id TEXT NOT NULL,
  order_type TEXT NOT NULL,
  status TEXT NOT NULL,
  effective_date TEXT NOT NULL,
  signed_status TEXT NOT NULL
);
CREATE TABLE garnishments (
  garnishment_id TEXT PRIMARY KEY,
  payroll_key TEXT NOT NULL,
  case_number TEXT NOT NULL,
  withholding_amount NUMERIC NOT NULL,
  status TEXT NOT NULL,
  authority_order_id TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
INSERT INTO employees VALUES
('E-902', 'PAY-1902', 'Robin Shah'),
('E-611', 'PAY-611', 'Cameron Brooks');
INSERT INTO court_orders VALUES
('ORD-2024-884', 'WG-2024-884', 'E-902', 'garnishment', 'superseded_by_release', '2024-04-12', 'signed_valid'),
('REL-2026-309', 'WG-2024-884', 'E-902', 'release', 'active', '2026-09-05', 'signed_valid'),
('ORD-2025-771', 'WG-2025-771', 'E-611', 'garnishment', 'active', '2025-11-02', 'signed_valid');
INSERT INTO garnishments VALUES
('GAR-1902', 'PAY-1902', 'WG-2024-884', 185.00, 'active', 'ORD-2024-884', '2026-08-31T09:00:00Z'),
('GAR-611', 'PAY-611', 'WG-2025-771', 140.00, 'active', 'ORD-2025-771', '2026-08-31T09:00:00Z');
