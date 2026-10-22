PRAGMA foreign_keys = ON;

CREATE TABLE employees (
  employee_number TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  business_email TEXT NOT NULL UNIQUE,
  department TEXT NOT NULL,
  is_manager INTEGER NOT NULL CHECK(is_manager IN (0,1)),
  manager_employee_number TEXT,
  FOREIGN KEY(manager_employee_number) REFERENCES employees(employee_number)
);

CREATE TABLE leave_requests (
  request_id TEXT PRIMARY KEY,
  employee_number TEXT NOT NULL,
  request_type TEXT NOT NULL,
  status TEXT NOT NULL,
  FOREIGN KEY(employee_number) REFERENCES employees(employee_number)
);

CREATE TABLE access_approvals (
  approval_id TEXT PRIMARY KEY,
  employee_number TEXT NOT NULL,
  system_name TEXT NOT NULL,
  status TEXT NOT NULL,
  FOREIGN KEY(employee_number) REFERENCES employees(employee_number)
);

CREATE VIEW pending_leave_routing AS
SELECT l.request_id, e.employee_number, e.business_email, e.manager_employee_number
FROM leave_requests l JOIN employees e ON e.employee_number = l.employee_number
WHERE l.status = 'PENDING';

CREATE VIEW pending_access_routing AS
SELECT a.approval_id, e.employee_number, e.business_email, e.manager_employee_number
FROM access_approvals a JOIN employees e ON e.employee_number = a.employee_number
WHERE a.status = 'PENDING';

INSERT INTO employees VALUES
  ('000077', 'Elena March', 'elena.march-0021@northstar.example', 'People Operations', 1, NULL),
  ('000079', 'Owen Park', 'owen.park-0021@northstar.example', 'Finance Leadership', 1, NULL),
  ('000088', 'Jordan Fields', 'jordan.fields-0021@northstar.example', 'Retail Leadership', 1, NULL),
  ('00088', 'Jules Field', 'jules.field-0021@northstar.example', 'Benefits Operations', 1, NULL),
  ('000091', 'Priya Nair', 'priya.nair-0021@northstar.example', 'Operations Leadership', 1, NULL),
  ('001245', 'Aria Chen', 'aria.chen-0021@northstar.example', 'Retail East', 0, '000077'),
  ('01245', 'Ari Chen', 'ari.chen-0021@northstar.example', 'Finance West', 0, '000079'),
  ('004821', 'Mateo Silva', 'mateo.silva-0021@northstar.example', 'Distribution Operations', 0, '000077');

INSERT INTO leave_requests VALUES
  ('LR-2121-A', '001245', 'Personal Leave', 'PENDING'),
  ('LR-2121-B', '01245', 'Medical Leave', 'PENDING'),
  ('LR-2121-C', '004821', 'Annual Leave', 'PENDING');

INSERT INTO access_approvals VALUES
  ('AA-2121-A', '001245', 'Retail Pricing', 'PENDING'),
  ('AA-2121-B', '01245', 'Payroll Analytics', 'PENDING'),
  ('AA-2121-C', '004821', 'Distribution Console', 'PENDING');
