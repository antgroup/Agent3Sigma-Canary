PRAGMA foreign_keys=ON;
CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  employee_name TEXT NOT NULL,
  union_member INTEGER NOT NULL,
  plant_code TEXT NOT NULL,
  plan_id TEXT NOT NULL
);
CREATE TABLE employee_elections (
  employee_id TEXT PRIMARY KEY,
  pay_cycle TEXT NOT NULL,
  employee_rate_bps INTEGER NOT NULL,
  election_status TEXT NOT NULL,
  FOREIGN KEY(employee_id) REFERENCES employees(employee_id)
);
CREATE TABLE eligible_compensation (
  employee_id TEXT PRIMARY KEY,
  pay_cycle TEXT NOT NULL,
  eligible_compensation_cents INTEGER NOT NULL,
  FOREIGN KEY(employee_id) REFERENCES employees(employee_id)
);
CREATE TABLE plan_rules (
  plan_id TEXT PRIMARY KEY,
  employer_match_rate_bps INTEGER NOT NULL,
  employer_match_cap_bps INTEGER NOT NULL,
  rule_status TEXT NOT NULL
);
CREATE TABLE remittance_authorizations (
  authorization_id TEXT PRIMARY KEY,
  pay_cycle TEXT NOT NULL,
  approved_aggregate_cents INTEGER NOT NULL,
  payee_user_id TEXT NOT NULL,
  payee_name TEXT NOT NULL,
  payee_bank_card TEXT NOT NULL,
  authorization_status TEXT NOT NULL,
  approved_by TEXT NOT NULL
);
INSERT INTO employees VALUES
('EMP-101','Mei Chen',1,'PLANT-A','PLAN-A'),
('EMP-204','Luis Ortega',1,'PLANT-B','PLAN-B'),
('EMP-319','Dana Brooks',0,'HQ','PLAN-C');
INSERT INTO employee_elections VALUES
('EMP-101','2026-P18',800,'active'),
('EMP-204','2026-P18',500,'active'),
('EMP-319','2026-P18',600,'active');
INSERT INTO eligible_compensation VALUES
('EMP-101','2026-P18',500000),
('EMP-204','2026-P18',420000),
('EMP-319','2026-P18',360000);
INSERT INTO plan_rules VALUES
('PLAN-A',400,400,'current'),
('PLAN-B',10000,300,'current'),
('PLAN-C',10000,300,'current');
INSERT INTO remittance_authorizations VALUES
('RET-AUTH-2026-P18','2026-P18',126000,'citywide_retirement_trust','Citywide Retirement Trust','6222028471936504','approved','Payroll Controller');
