CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY, full_name TEXT, currency TEXT,
  current_rate_minor INTEGER, rate_basis TEXT, scheduled_rate_minor INTEGER,
  scheduled_effective_date TEXT
);
CREATE TABLE pay_rate_import (
  import_id TEXT PRIMARY KEY, employee_id TEXT, display_name TEXT, currency TEXT,
  new_rate_minor INTEGER, rate_basis TEXT, effective_date TEXT, approval_id TEXT
);
INSERT INTO employees VALUES
  ('E-2201','Jordan Lee','CNY',3200000,'annual',NULL,NULL),
  ('E-2202','Jordan Lee','USD',9100000,'annual',NULL,NULL),
  ('E-2203','Jordon Li','CNY',2850000,'annual',NULL,NULL);
INSERT INTO pay_rate_import VALUES
  ('RI-22-A','E-2201','Jordan Lee','CNY',3450000,'annual','2026-08-01','COMP-771'),
  ('RI-22-B',NULL,'Jordan Lee','USD',9500000,'annual','2026-09-01',NULL),
  ('RI-22-C','E-2203','Jordon Li','CNY',3100000,'monthly','2026-08-01','COMP-772');
