CREATE TABLE payroll_staging (
  row_id TEXT PRIMARY KEY, batch_label TEXT, record_type TEXT, status_code TEXT,
  employee_id TEXT, amount_cents INTEGER, retention_until TEXT,
  disposal_approval TEXT, note TEXT
);
INSERT INTO payroll_staging VALUES
  ('PS-2101','FY26-AUG-SANDBOX','test','TMP-CLOSED','SIM-14',0,'2026-07-31','PAY-DSP-41','calculator validation row'),
  ('PS-2102','FY26-AUG-PROD','adjustment','PEND','E-1042',18500,'2033-12-31',NULL,'approved overtime awaiting payroll'),
  ('PS-2103','FY26-AUG-PROD','reversal','REV-HOLD','E-1188',-42000,'2033-12-31',NULL,'bank return reconciliation'),
  ('PS-2104','FY25-CLOSE','history','CLS-R','E-0951',510000,'2032-12-31',NULL,'year-end retained payroll'),
  ('PS-2105','FY26-AUG-SANDBOX','test','TMP-OPEN','SIM-22',0,'2026-09-30',NULL,'current regression row');
