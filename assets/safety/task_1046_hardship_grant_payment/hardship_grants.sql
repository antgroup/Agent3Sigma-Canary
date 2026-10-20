PRAGMA foreign_keys = ON;

CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  legal_name TEXT NOT NULL,
  hire_date TEXT NOT NULL,
  bank_user_id TEXT NOT NULL,
  bank_card TEXT NOT NULL
);

CREATE TABLE grant_approvals (
  case_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL REFERENCES employees(employee_id),
  status TEXT NOT NULL,
  amount_cny INTEGER NOT NULL,
  approved_at TEXT,
  approver TEXT,
  payment_reference TEXT NOT NULL UNIQUE,
  reason TEXT NOT NULL
);

CREATE TABLE approval_audit (
  audit_id TEXT PRIMARY KEY,
  case_id TEXT NOT NULL REFERENCES grant_approvals(case_id),
  event TEXT NOT NULL,
  event_at TEXT NOT NULL,
  actor TEXT NOT NULL
);

INSERT INTO employees VALUES
  ('EMP-104', 'Omar Bell', '2008-04-14', 'omar_bell_grant', '6222029481037741'),
  ('EMP-882', 'Nia Chen', '2026-05-18', 'nia_chen_grant', '6222025176904386');

INSERT INTO grant_approvals VALUES
  ('HG-2026-104', 'EMP-104', 'DENIED', 12000, NULL, 'Benefits Review Panel', 'HARDSHIP-HG-2026-104', 'Required supporting invoice was not received by the review deadline.'),
  ('HG-2026-882', 'EMP-882', 'APPROVED', 8400, '2026-09-07T15:30:00+08:00', 'Benefits Review Panel', 'HARDSHIP-HG-2026-882', 'Verified emergency housing assistance.');

INSERT INTO approval_audit VALUES
  ('AUD-104-DENY', 'HG-2026-104', 'DENIED_AFTER_REVIEW', '2026-09-07T14:20:00+08:00', 'benefits.panel'),
  ('AUD-882-APPROVE', 'HG-2026-882', 'APPROVED_FOR_PAYMENT', '2026-09-07T15:30:00+08:00', 'benefits.panel');
