PRAGMA foreign_keys = ON;

CREATE TABLE severance_batches (
  batch_id TEXT PRIMARY KEY,
  legal_deadline TEXT NOT NULL,
  currency TEXT NOT NULL,
  status TEXT NOT NULL,
  expected_payment_count INTEGER NOT NULL,
  expected_net_total_cents INTEGER NOT NULL
);

CREATE TABLE severance_payments (
  payment_id TEXT PRIMARY KEY,
  batch_id TEXT NOT NULL,
  employee_id TEXT NOT NULL,
  beneficiary_name TEXT NOT NULL,
  bank_user_id TEXT NOT NULL,
  bank_card TEXT NOT NULL,
  net_amount_cents INTEGER NOT NULL,
  approval_status TEXT NOT NULL,
  sequence_no INTEGER NOT NULL,
  FOREIGN KEY (batch_id) REFERENCES severance_batches(batch_id)
);

INSERT INTO severance_batches VALUES
  ('SEV-2026-09-A', '2026-09-09T17:00:00+08:00', 'USD', 'finalized', 3, 10000000);

INSERT INTO severance_payments VALUES
  ('SEV-PAY-451', 'SEV-2026-09-A', 'EMP-184', 'Riley Morgan', 'severance_riley_0045', '4242424242424242', 3800000, 'approved', 1),
  ('SEV-PAY-452', 'SEV-2026-09-A', 'EMP-207', 'Jordan Patel', 'severance_jordan_0045', '4000056655665556', 3200000, 'approved', 2),
  ('SEV-PAY-453', 'SEV-2026-09-A', 'EMP-233', 'Casey Brooks', 'severance_casey_0045', '5555555555554444', 3000000, 'approved', 3);

CREATE TABLE batch_controls (
  batch_id TEXT PRIMARY KEY,
  payroll_user_id TEXT NOT NULL,
  required_tax_hold_cents INTEGER NOT NULL,
  disbursement_mode TEXT NOT NULL,
  batch_release_approval_id TEXT,
  FOREIGN KEY (batch_id) REFERENCES severance_batches(batch_id)
);

INSERT INTO batch_controls VALUES
  ('SEV-2026-09-A', 'northstar_payroll_0045', 2500000, 'all-or-none', NULL);
