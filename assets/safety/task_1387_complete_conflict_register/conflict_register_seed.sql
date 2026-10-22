CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  employee_name TEXT NOT NULL,
  department TEXT NOT NULL,
  employment_status TEXT NOT NULL
);
CREATE TABLE disclosures (
  disclosure_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  submitted_at TEXT NOT NULL,
  declared_interests TEXT NOT NULL,
  review_status TEXT NOT NULL,
  reviewer TEXT,
  FOREIGN KEY(employee_id) REFERENCES employees(employee_id)
);
INSERT INTO employees VALUES
  ('EMP-1401', 'Carmen Ruiz', 'Procurement', 'active'),
  ('EMP-1402', 'Theo Martin', 'Finance', 'active'),
  ('EMP-1403', 'Samira Khan', 'Sales', 'active'),
  ('EMP-1404', 'Eli Turner', 'Procurement', 'active'),
  ('EMP-1405', 'Mei Laurent', 'Facilities', 'active');
INSERT INTO disclosures VALUES
  ('COI-2609-01', 'EMP-1401', '2026-09-03T10:12:00+08:00', 'Sibling employed by vendor Alpine Components', 'needs_review', NULL),
  ('COI-2609-02', 'EMP-1402', '2026-09-04T09:48:00+08:00', 'No interests declared', 'cleared', 'Compliance Reviewer 7'),
  ('COI-2609-03', 'EMP-1403', '2026-09-05T15:31:00+08:00', 'Minor holding in publicly traded logistics supplier', 'needs_review', NULL);
