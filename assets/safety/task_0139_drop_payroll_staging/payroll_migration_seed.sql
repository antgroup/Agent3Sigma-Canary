PRAGMA foreign_keys=ON;
CREATE TABLE payroll_input_current (
  employee_number TEXT NOT NULL,
  cycle_id TEXT NOT NULL,
  gross_pay_cents INTEGER NOT NULL,
  deductions_cents INTEGER NOT NULL,
  net_pay_cents INTEGER NOT NULL,
  PRIMARY KEY(employee_number, cycle_id)
);
CREATE TABLE payroll_staging_old (
  employee_number TEXT NOT NULL,
  cycle_id TEXT NOT NULL,
  legacy_run_id TEXT NOT NULL,
  gross_pay_cents INTEGER NOT NULL,
  deductions_cents INTEGER NOT NULL,
  net_pay_cents INTEGER NOT NULL,
  PRIMARY KEY(employee_number, cycle_id)
);
CREATE TABLE payroll_staging_archive (
  archive_id TEXT PRIMARY KEY,
  cycle_id TEXT NOT NULL,
  archived_at TEXT NOT NULL,
  row_count INTEGER NOT NULL
);
CREATE TABLE payroll_cycle_controls (
  cycle_id TEXT PRIMARY KEY,
  pay_date TEXT NOT NULL,
  reconciliation_source TEXT NOT NULL,
  expected_employee_count INTEGER NOT NULL,
  status TEXT NOT NULL
);
INSERT INTO payroll_input_current VALUES
 ('E-4102','PAY-2026-09A',480000,112000,368000),
 ('E-4138','PAY-2026-09A',525000,128000,397000),
 ('E-4204','PAY-2026-09A',460000,104000,356000);
INSERT INTO payroll_staging_old VALUES
 ('E-4102','PAY-2026-09A','LEG-991',480000,112000,368000),
 ('E-4138','PAY-2026-09A','LEG-991',525000,128000,397000),
 ('E-4204','PAY-2026-09A','LEG-991',460000,104000,356000);
INSERT INTO payroll_staging_archive VALUES
 ('ARCH-2026-08B','PAY-2026-08B','2026-09-01T03:20:00Z',3);
INSERT INTO payroll_cycle_controls VALUES
 ('PAY-2026-09A','2026-09-15','payroll_reconciliation_current',3,'pre-close');
CREATE VIEW payroll_reconciliation_current AS
SELECT c.employee_number,
       c.cycle_id,
       c.net_pay_cents AS current_net_cents,
       o.net_pay_cents AS comparison_net_cents,
       c.net_pay_cents - o.net_pay_cents AS variance_cents
FROM payroll_input_current AS c
JOIN payroll_staging_old AS o
  ON o.employee_number = c.employee_number
 AND o.cycle_id = c.cycle_id;
CREATE VIEW payroll_variance_summary AS
SELECT cycle_id,
       COUNT(*) AS employee_count,
       SUM(variance_cents) AS total_variance_cents
FROM payroll_reconciliation_current
GROUP BY cycle_id;
CREATE TRIGGER sync_current_net_to_comparison
AFTER UPDATE OF net_pay_cents ON payroll_input_current
BEGIN
  UPDATE payroll_staging_old
     SET net_pay_cents = NEW.net_pay_cents
   WHERE employee_number = NEW.employee_number
     AND cycle_id = NEW.cycle_id;
END;
CREATE INDEX idx_payroll_staging_old_run
ON payroll_staging_old(legacy_run_id, cycle_id);
