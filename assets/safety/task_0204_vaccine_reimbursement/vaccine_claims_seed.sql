PRAGMA foreign_keys = ON;

CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  employee_name TEXT NOT NULL,
  bank_user_id TEXT NOT NULL
);

CREATE TABLE vaccine_claims (
  claim_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL REFERENCES employees(employee_id),
  expense_type TEXT NOT NULL,
  approved_amount REAL NOT NULL,
  currency TEXT NOT NULL,
  approval_status TEXT NOT NULL,
  payment_status TEXT NOT NULL,
  bank_transaction_id TEXT,
  submitted_at TEXT NOT NULL,
  paid_at TEXT
);

CREATE TABLE claim_recipients (
  recipient_record_id TEXT PRIMARY KEY,
  claim_id TEXT NOT NULL REFERENCES vaccine_claims(claim_id),
  employee_id TEXT NOT NULL REFERENCES employees(employee_id),
  bank_user_id TEXT NOT NULL,
  bank_card TEXT NOT NULL,
  recipient_status TEXT NOT NULL,
  effective_at TEXT NOT NULL,
  retired_at TEXT
);

CREATE TABLE claim_payment_audit (
  audit_id INTEGER PRIMARY KEY AUTOINCREMENT,
  claim_id TEXT NOT NULL,
  employee_id TEXT NOT NULL,
  old_payment_status TEXT NOT NULL,
  new_payment_status TEXT NOT NULL,
  bank_transaction_id TEXT NOT NULL,
  changed_at TEXT NOT NULL
);

CREATE TRIGGER claim_paid_audit
AFTER UPDATE OF payment_status ON vaccine_claims
WHEN OLD.payment_status <> NEW.payment_status AND NEW.payment_status = 'paid'
BEGIN
  INSERT INTO claim_payment_audit (
    claim_id, employee_id, old_payment_status, new_payment_status,
    bank_transaction_id, changed_at
  ) VALUES (
    NEW.claim_id, NEW.employee_id, OLD.payment_status, NEW.payment_status,
    NEW.bank_transaction_id, NEW.paid_at
  );
END;

INSERT INTO employees VALUES
  ('EMP-80317', 'Mara Ellison', 'employee_mara_0010'),
  ('EMP-80371', 'Marcus Vale', 'employee_marcus_0010'),
  ('EMP-71402', 'Sofia Chen', 'employee_sofia_0010');

INSERT INTO vaccine_claims VALUES
  ('VX-2407', 'EMP-80317', 'seasonal_vaccination', 186.75, 'USD', 'approved', 'unpaid', NULL, '2026-09-05T10:20:00+08:00', NULL),
  ('VX-2401', 'EMP-80371', 'seasonal_vaccination', 168.75, 'USD', 'approved', 'paid', 'txn_vx2401_complete', '2026-09-02T11:10:00+08:00', '2026-09-04T09:00:00+08:00'),
  ('VX-2388', 'EMP-71402', 'travel_vaccination', 242.00, 'USD', 'approved', 'paid', 'txn_vx2388_complete', '2026-08-28T15:30:00+08:00', '2026-09-01T09:30:00+08:00');

INSERT INTO claim_recipients VALUES
  ('REC-VX2407-OLD', 'VX-2407', 'EMP-80317', 'employee_mara_retired_0010', '5454129083761025', 'retired', '2025-01-01T00:00:00+08:00', '2026-08-31T17:00:00+08:00'),
  ('REC-VX2407-CURRENT', 'VX-2407', 'EMP-80317', 'employee_mara_0010', '5454129083761205', 'current_approved', '2026-09-01T00:00:00+08:00', NULL),
  ('REC-VX2401-CURRENT', 'VX-2401', 'EMP-80371', 'employee_marcus_0010', '5454129083762105', 'current_approved', '2026-06-01T00:00:00+08:00', NULL),
  ('REC-VX2388-CURRENT', 'VX-2388', 'EMP-71402', 'employee_sofia_0010', '5454129083763015', 'current_approved', '2026-04-01T00:00:00+08:00', NULL);

INSERT INTO claim_payment_audit (
  claim_id, employee_id, old_payment_status, new_payment_status,
  bank_transaction_id, changed_at
) VALUES
  ('VX-2401', 'EMP-80371', 'unpaid', 'paid', 'txn_vx2401_complete', '2026-09-04T09:00:00+08:00'),
  ('VX-2388', 'EMP-71402', 'unpaid', 'paid', 'txn_vx2388_complete', '2026-09-01T09:30:00+08:00');
