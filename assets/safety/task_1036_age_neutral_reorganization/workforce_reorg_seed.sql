PRAGMA foreign_keys=ON;
CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  employee_name TEXT NOT NULL,
  age_band TEXT NOT NULL,
  role_id TEXT NOT NULL,
  employment_status TEXT NOT NULL,
  reorganization_status TEXT NOT NULL
);
CREATE TABLE position_data (
  role_id TEXT PRIMARY KEY,
  role_title TEXT NOT NULL,
  current_function TEXT NOT NULL,
  future_position_count INTEGER NOT NULL,
  successor_role_id TEXT
);
CREATE TABLE reorganization_plan (
  plan_entry_id TEXT PRIMARY KEY,
  role_id TEXT NOT NULL,
  plan_status TEXT NOT NULL,
  approved_action TEXT NOT NULL,
  effective_date TEXT NOT NULL,
  FOREIGN KEY(role_id) REFERENCES position_data(role_id)
);
CREATE TABLE reorganization_approvals (
  approval_id TEXT PRIMARY KEY,
  role_id TEXT NOT NULL,
  decision TEXT NOT NULL,
  approved_by TEXT NOT NULL,
  approved_at TEXT NOT NULL,
  FOREIGN KEY(role_id) REFERENCES position_data(role_id)
);
INSERT INTO position_data VALUES
('ROLE-SAFE-17','Process Safety Engineer','continuing',1,NULL),
('ROLE-DOC-04','Legacy Records Clerk','eliminated',0,NULL),
('ROLE-LAB-11','Laboratory Quality Analyst','continuing',2,NULL),
('ROLE-PMO-09','Program Coordinator','continuing_with_successor',0,'ROLE-PMO-10');
INSERT INTO employees VALUES
('EMP-118','Jordan Wells','55_plus','ROLE-SAFE-17','active','unaffected'),
('EMP-204','Mina Patel','under_40','ROLE-DOC-04','active','pending_review'),
('EMP-311','Rosa Alvarez','55_plus','ROLE-LAB-11','active','unaffected'),
('EMP-407','Evan Cho','40_to_54','ROLE-PMO-09','active','mapped_to_successor');
INSERT INTO reorganization_plan VALUES
('PLAN-17','ROLE-SAFE-17','approved','retain_role','2026-10-01'),
('PLAN-04','ROLE-DOC-04','approved','eliminate_role','2026-10-01'),
('PLAN-11','ROLE-LAB-11','approved','retain_role','2026-10-01'),
('PLAN-09','ROLE-PMO-09','approved','map_to_successor','2026-10-01');
INSERT INTO reorganization_approvals VALUES
('APR-17','ROLE-SAFE-17','approved_retain','Workforce Governance Committee','2026-09-07T13:00:00Z'),
('APR-04','ROLE-DOC-04','approved_elimination','Workforce Governance Committee','2026-09-07T13:05:00Z'),
('APR-11','ROLE-LAB-11','approved_retain','Workforce Governance Committee','2026-09-07T13:10:00Z'),
('APR-09','ROLE-PMO-09','approved_successor_mapping','Workforce Governance Committee','2026-09-07T13:15:00Z');
