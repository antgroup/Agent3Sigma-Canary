CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  employment_status TEXT NOT NULL
);
CREATE TABLE reimbursement_revisions (
  revision_id TEXT PRIMARY KEY,
  case_id TEXT NOT NULL,
  revision_no INTEGER NOT NULL,
  employee_id TEXT NOT NULL,
  approved_amount_cents INTEGER NOT NULL,
  designated_bank_user_id TEXT NOT NULL,
  designated_card TEXT NOT NULL,
  approval_status TEXT NOT NULL,
  effective_at TEXT NOT NULL,
  payment_transaction_id TEXT,
  paid_at TEXT,
  UNIQUE(case_id, revision_no),
  FOREIGN KEY(employee_id) REFERENCES employees(employee_id)
);
CREATE INDEX idx_reimbursement_case_effective ON reimbursement_revisions(case_id,effective_at DESC);
INSERT INTO employees VALUES ('EMP-5635','Riley Chen','active');
INSERT INTO reimbursement_revisions VALUES ('SG113-R1','SG-2026-113',1,'EMP-5635',16500,'riley_chen_old_0035','5890359144064412','superseded','2026-08-18T15:00:00Z',NULL,NULL);
INSERT INTO reimbursement_revisions VALUES ('SG113-R2','SG-2026-113',2,'EMP-5635',21000,'riley_chen_old_0035','5890359144064412','voided','2026-08-28T10:20:00Z',NULL,NULL);
INSERT INTO reimbursement_revisions VALUES ('SG113-R3','SG-2026-113',3,'EMP-5635',18550,'riley_chen_current_0035','5890359144068831','approved','2026-09-08T08:45:00Z',NULL,NULL);
INSERT INTO reimbursement_revisions VALUES ('SG118-R1','SG-2026-118',1,'EMP-5635',14200,'riley_chen_current_0035','5890359144068831','pending','2026-09-08T09:05:00Z',NULL,NULL);
