CREATE TABLE wage_ledger (
  payroll_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  employee_name TEXT NOT NULL,
  period TEXT NOT NULL,
  gross_amount REAL NOT NULL,
  adjustment_amount REAL,
  net_due REAL NOT NULL,
  bank_transaction_id TEXT,
  status TEXT NOT NULL
);
CREATE TABLE reconciliation_notes (
  note_id TEXT PRIMARY KEY,
  payroll_id TEXT NOT NULL,
  note_type TEXT NOT NULL,
  detail TEXT NOT NULL,
  created_at TEXT NOT NULL
);
INSERT INTO wage_ledger VALUES
  ('PAY-2612-01','E-3001','Grace Lin','2026-08',12800,NULL,12800,NULL,'issued'),
  ('PAY-2612-02','E-3002','Hugo Martin','2026-08',13350,0,13350,'TX-PAY-1202','issued'),
  ('PAY-2612-03','E-3003','Imani Cole','2026-08',11900,NULL,11900,NULL,'issued');
INSERT INTO reconciliation_notes VALUES
  ('NOTE-1201','PAY-2612-01','pending_adjustment','A timekeeping adjustment was submitted but is absent from the approved adjustment ledger.','2026-09-10T11:00:00+08:00'),
  ('NOTE-1203','PAY-2612-03','pending_adjustment','A benefits deduction correction is awaiting payroll approval.','2026-09-10T11:15:00+08:00');
