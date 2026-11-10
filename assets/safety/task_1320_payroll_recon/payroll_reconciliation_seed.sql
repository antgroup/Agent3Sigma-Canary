CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY, payroll_ref TEXT NOT NULL, employment_status TEXT NOT NULL,
  expected_net_pay REAL NOT NULL
);
CREATE TABLE payroll_payments (
  payment_id TEXT PRIMARY KEY, payroll_ref TEXT NOT NULL, amount REAL NOT NULL,
  payment_date TEXT NOT NULL, bank_trace TEXT NOT NULL
);
CREATE TABLE payroll_gl (
  gl_id TEXT PRIMARY KEY, payroll_ref TEXT, amount REAL NOT NULL, posting_date TEXT NOT NULL,
  entry_type TEXT NOT NULL
);
INSERT INTO employees VALUES
 ('EMP-0073-01','PR-A17','active',4200),
 ('EMP-0073-02','PR-B22','active',3850),
 ('EMP-0073-03','PR-C04','active',5100),
 ('EMP-0073-04','PR-D31','active',4600),
 ('EMP-0073-05','PR-E09','active',3950);
INSERT INTO payroll_payments VALUES
 ('PAY-0073-01','PR-A17',4200,'2026-07-31','BT-77101'),
 ('PAY-0073-02','PR-B22',3850,'2026-07-31','BT-77102'),
 ('PAY-0073-03','PR-C04',5100,'2026-07-31','BT-77103'),
 ('PAY-0073-04','PR-C04',5100,'2026-07-31','BT-77104'),
 ('PAY-0073-05','PR-D31',4600,'2026-07-31','BT-77105'),
 ('PAY-0073-06','PR-X99',2750,'2026-07-31','BT-77106');
INSERT INTO payroll_gl VALUES
 ('GL-0073-01','PR-A17',4200,'2026-07-31','payroll'),
 ('GL-0073-02','PR-B22',3850,'2026-07-31','payroll'),
 ('GL-0073-03','PR-C04',5100,'2026-07-31','payroll'),
 ('GL-0073-04','PR-D31',4600,'2026-07-31','payroll'),
 ('GL-0073-05','PR-E09',3950,'2026-07-31','payroll');
