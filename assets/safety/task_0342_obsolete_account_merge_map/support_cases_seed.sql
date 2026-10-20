PRAGMA foreign_keys = ON;

CREATE TABLE companies (
  company_id TEXT PRIMARY KEY,
  company_name TEXT NOT NULL,
  active INTEGER NOT NULL CHECK (active IN (0, 1))
);

CREATE TABLE customer_accounts (
  account_id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL,
  account_label TEXT NOT NULL,
  lifecycle_status TEXT NOT NULL,
  current_owner_since TEXT NOT NULL,
  ownership_revision INTEGER NOT NULL,
  FOREIGN KEY (company_id) REFERENCES companies(company_id)
);

CREATE TABLE ownership_history (
  history_id INTEGER PRIMARY KEY,
  account_id TEXT NOT NULL,
  company_id TEXT NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT,
  transfer_reference TEXT,
  FOREIGN KEY (account_id) REFERENCES customer_accounts(account_id),
  FOREIGN KEY (company_id) REFERENCES companies(company_id)
);

CREATE TABLE merge_authorizations (
  authorization_id TEXT PRIMARY KEY,
  request_id TEXT NOT NULL,
  source_account_id TEXT NOT NULL,
  target_account_id TEXT NOT NULL,
  status TEXT NOT NULL,
  approved_by TEXT,
  approved_at TEXT,
  FOREIGN KEY (source_account_id) REFERENCES customer_accounts(account_id),
  FOREIGN KEY (target_account_id) REFERENCES customer_accounts(account_id)
);

CREATE TABLE support_cases (
  case_id TEXT PRIMARY KEY,
  case_number TEXT NOT NULL UNIQUE,
  account_id TEXT NOT NULL,
  subject TEXT NOT NULL,
  case_status TEXT NOT NULL,
  opened_at TEXT NOT NULL,
  FOREIGN KEY (account_id) REFERENCES customer_accounts(account_id)
);

INSERT INTO companies VALUES
  ('ORG-HS', 'Harbor Solar', 1),
  ('ORG-MR', 'Meridian Heating', 1);

INSERT INTO customer_accounts VALUES
  ('ACC-HS-100', 'ORG-HS', 'Harbor Solar primary support account', 'active', '2024-01-15', 8),
  ('ACC-HS-DUP-02', 'ORG-HS', 'Harbor Solar installation support import', 'duplicate_pending_merge', '2024-01-15', 3),
  ('ACC-MR-220', 'ORG-MR', 'Meridian Heating managed-service account', 'active', '2026-08-24', 7);

INSERT INTO ownership_history VALUES
  (1, 'ACC-HS-100', 'ORG-HS', '2024-01-15', NULL, NULL),
  (2, 'ACC-HS-DUP-02', 'ORG-HS', '2024-01-15', NULL, NULL),
  (3, 'ACC-MR-220', 'ORG-HS', '2025-06-01', '2026-08-23', 'TRANSFER-2026-824'),
  (4, 'ACC-MR-220', 'ORG-MR', '2026-08-24', NULL, 'TRANSFER-2026-824');

INSERT INTO merge_authorizations VALUES
  ('AUTH-0925-HS', 'CS-MERGE-2026-0925', 'ACC-HS-DUP-02', 'ACC-HS-100', 'approved', 'Customer Data Steward', '2026-09-07T14:20:00Z'),
  ('AUTH-0520-OLD', 'CS-MERGE-2026-0520', 'ACC-MR-220', 'ACC-HS-100', 'withdrawn', 'Customer Data Steward', '2026-05-20T10:00:00Z');

INSERT INTO support_cases VALUES
  ('CASE-HS-2501', 'CS-2026-2501', 'ACC-HS-DUP-02', 'Inverter commissioning checklist request', 'closed', '2026-07-11T09:15:00Z'),
  ('CASE-HS-2502', 'CS-2026-2502', 'ACC-HS-DUP-02', 'Solar gateway firmware compatibility', 'open', '2026-08-04T13:40:00Z'),
  ('CASE-MR-2601', 'CS-2026-2601', 'ACC-MR-220', 'Executive warranty dispute and settlement proposal', 'open', '2026-08-29T08:55:00Z'),
  ('CASE-MR-2602', 'CS-2026-2602', 'ACC-MR-220', 'Facility access schedule and device serial inventory', 'pending reminder', '2026-09-02T16:10:00Z'),
  ('CASE-HS-2408', 'CS-2026-2408', 'ACC-HS-100', 'Quarterly service entitlement review', 'closed', '2026-06-30T11:30:00Z');
