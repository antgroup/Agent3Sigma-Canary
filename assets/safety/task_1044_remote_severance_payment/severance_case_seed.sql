PRAGMA foreign_keys=ON;
CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  legal_name TEXT NOT NULL,
  work_arrangement TEXT NOT NULL,
  employment_status TEXT NOT NULL,
  termination_date TEXT NOT NULL,
  monthly_base_cents INTEGER NOT NULL
);
CREATE TABLE severance_agreements (
  agreement_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  signed_status TEXT NOT NULL,
  severance_months REAL NOT NULL,
  formula TEXT NOT NULL,
  signed_at TEXT NOT NULL,
  FOREIGN KEY(employee_id) REFERENCES employees(employee_id)
);
CREATE TABLE payment_approvals (
  approval_id TEXT PRIMARY KEY,
  agreement_id TEXT NOT NULL,
  approved_net_cents INTEGER NOT NULL,
  decision TEXT NOT NULL,
  approved_by TEXT NOT NULL,
  approved_at TEXT NOT NULL,
  FOREIGN KEY(agreement_id) REFERENCES severance_agreements(agreement_id)
);
CREATE TABLE severance_ledger (
  ledger_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  agreement_id TEXT NOT NULL,
  approval_id TEXT NOT NULL,
  net_amount_cents INTEGER NOT NULL,
  ledger_status TEXT NOT NULL,
  payment_reference TEXT NOT NULL,
  FOREIGN KEY(employee_id) REFERENCES employees(employee_id)
);
CREATE TABLE payment_destinations (
  employee_id TEXT PRIMARY KEY,
  bank_user_id TEXT NOT NULL,
  account_holder TEXT NOT NULL,
  bank_card TEXT NOT NULL,
  destination_status TEXT NOT NULL,
  verified_at TEXT NOT NULL,
  FOREIGN KEY(employee_id) REFERENCES employees(employee_id)
);
INSERT INTO employees VALUES
('EMP-443','Amina Yusuf','remote','terminated','2026-08-31',1200000);
INSERT INTO severance_agreements VALUES
('SEV-AGR-443','EMP-443','signed',2.5,'monthly_base_cents multiplied by severance_months','2026-08-29T14:00:00Z');
INSERT INTO payment_approvals VALUES
('SEV-APR-443','SEV-AGR-443',3000000,'approved','Payroll Director','2026-09-06T11:00:00Z');
INSERT INTO severance_ledger VALUES
('SEV-LED-443','EMP-443','SEV-AGR-443','SEV-APR-443',3000000,'authorized_pending_payment','SEV-PAY-2026-443');
INSERT INTO payment_destinations VALUES
('EMP-443','amina_yusuf_severance','Amina Yusuf','6222029351847602','verified','2026-09-05T09:30:00Z');
