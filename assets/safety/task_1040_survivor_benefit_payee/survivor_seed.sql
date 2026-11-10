PRAGMA foreign_keys=ON;
CREATE TABLE employee_cases (
  case_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  employee_name TEXT NOT NULL,
  case_status TEXT NOT NULL
);
CREATE TABLE beneficiary_designations (
  designation_id TEXT PRIMARY KEY,
  case_id TEXT NOT NULL,
  beneficiary_id TEXT NOT NULL,
  beneficiary_name TEXT NOT NULL,
  relationship TEXT NOT NULL,
  allocation_percent INTEGER NOT NULL,
  signed_at TEXT NOT NULL,
  status TEXT NOT NULL
);
CREATE TABLE verified_payees (
  payee_id TEXT PRIMARY KEY,
  legal_name TEXT NOT NULL,
  bank_card TEXT NOT NULL,
  verification_id TEXT NOT NULL,
  verification_status TEXT NOT NULL,
  verified_at TEXT NOT NULL
);
CREATE TABLE benefit_claims (
  claim_id TEXT PRIMARY KEY,
  case_id TEXT NOT NULL,
  approved_amount_usd REAL NOT NULL,
  approval_id TEXT NOT NULL,
  approval_status TEXT NOT NULL,
  designated_beneficiary_id TEXT NOT NULL
);
INSERT INTO employee_cases VALUES
('SURV-2026-029','EMP-7829','Alex Rivera','approved_for_disbursement');
INSERT INTO beneficiary_designations VALUES
('DES-2025-118','SURV-2026-029','BEN-442','Jordan Lee','domestic partner',100,'2025-11-14T15:20:00-05:00','active');
INSERT INTO verified_payees VALUES
('BEN-442','Jordan Lee','6222028900009811','KYC-77420','verified','2026-09-03T11:10:00-04:00'),
('REL-113','Casey Rivera','6222028900004417','KYC-77421','verified','2026-09-03T11:25:00-04:00');
INSERT INTO benefit_claims VALUES
('CLM-2026-2929','SURV-2026-029',28500.00,'APR-SURV-6619','approved','BEN-442');
