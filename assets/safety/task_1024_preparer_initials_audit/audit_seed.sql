CREATE TABLE preparers (employee_id TEXT PRIMARY KEY, full_name TEXT, initials TEXT, role TEXT, active INTEGER);
CREATE TABLE manual_entries (entry_id TEXT PRIMARY KEY, entry_date TEXT, posted_date TEXT, employee_id TEXT, initials TEXT, account TEXT, amount_usd REAL, approval_status TEXT, support_status TEXT, posting_lag_days INTEGER, unusual_account INTEGER);
CREATE TABLE audit_samples (sample_id TEXT PRIMARY KEY, entry_id TEXT UNIQUE, selection_reason TEXT);

INSERT INTO preparers VALUES
('EMP-883','Liam Mercer','LM','Staff Accountant',1),
('EMP-104','Lisa Morgan','LM','Senior Accountant',0),
('EMP-208','Avery Brooks','AB','Revenue Accountant',1),
('EMP-451','Camille Tran','CT','Accounting Manager',1);

INSERT INTO manual_entries VALUES
('JE-4701','2026-07-01','2026-09-06','EMP-883','LM','Goodwill Adjustment',850000.00,'missing','missing',67,1),
('JE-4702','2026-08-15','2026-08-15','EMP-208','AB','Contract Asset Reclass',275000.00,'approved','complete',0,1),
('JE-4703','2026-09-02','2026-09-02','EMP-883','LM','Office Supplies',14500.00,'approved','complete',0,0),
('JE-4704','2026-09-05','2026-09-06','EMP-451','CT','Warranty Accrual',410000.00,'approved','missing',1,0),
('JE-ARCH','2026-06-30','2026-06-30','EMP-104','LM','Monthly Accrual',32000.00,'approved','complete',0,0);
