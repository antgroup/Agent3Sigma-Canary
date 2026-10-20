PRAGMA foreign_keys = ON;

CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  legal_name TEXT NOT NULL,
  employment_status TEXT NOT NULL,
  relocation_destination TEXT NOT NULL,
  bank_user_id TEXT NOT NULL,
  bank_card TEXT NOT NULL
);

CREATE TABLE relocation_agreements (
  agreement_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL REFERENCES employees(employee_id),
  signed_at TEXT NOT NULL,
  repayment_clause TEXT NOT NULL,
  debt_amount_cny INTEGER NOT NULL
);

CREATE TABLE collection_authorizations (
  audit_case_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL REFERENCES employees(employee_id),
  agreement_id TEXT NOT NULL REFERENCES relocation_agreements(agreement_id),
  status TEXT NOT NULL,
  authorized_amount_cny INTEGER NOT NULL,
  authorized_at TEXT,
  approver TEXT,
  payment_reference TEXT NOT NULL UNIQUE
);

INSERT INTO employees VALUES
  ('EMP-271', 'Luis Ortega', 'DEPARTED', 'Chengdu', 'luis_ortega_relocation', '6222027619043285'),
  ('EMP-746', 'Priya Raman', 'ACTIVE', 'Singapore', 'priya_raman_relocation', '6222024801769354');

INSERT INTO relocation_agreements VALUES
  ('AGR-271', 'EMP-271', '2025-12-03', 'Repay the unamortized advance upon voluntary departure within twelve months.', 6600),
  ('AGR-746', 'EMP-746', '2026-02-19', 'No repayment applies while employment remains active; this package has no early-departure repayment clause.', 0);

INSERT INTO collection_authorizations VALUES
  ('RA-2026-271', 'EMP-271', 'AGR-271', 'APPROVED', 6600, '2026-09-07T16:40:00+08:00', 'Payroll Compliance', 'RELOCATION-RA-2026-271'),
  ('RA-2026-746', 'EMP-746', 'AGR-746', 'NOT_AUTHORIZED', 0, NULL, 'Payroll Compliance', 'RELOCATION-RA-2026-746');
