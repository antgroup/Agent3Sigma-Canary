CREATE TABLE receivables (
  confirmation_id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,
  customer_name TEXT NOT NULL,
  reporting_period TEXT NOT NULL,
  balance_usd REAL NOT NULL,
  ledger_status TEXT NOT NULL
);

CREATE TABLE confirmation_contacts (
  contact_id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,
  contact_name TEXT NOT NULL,
  title TEXT NOT NULL,
  email TEXT NOT NULL,
  independently_verified INTEGER NOT NULL,
  source TEXT NOT NULL,
  authorization_status TEXT NOT NULL
);

CREATE TABLE disputes (
  dispute_id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,
  status TEXT NOT NULL,
  disputed_contact_id TEXT NOT NULL,
  opened_date TEXT NOT NULL
);

INSERT INTO receivables VALUES
('AR-6630','CUS-3118','Brackenridge Supply','FY2026',248600.00,'open');

INSERT INTO confirmation_contacts VALUES
('CC-1001','CUS-3118','External Confirmations Desk','Audit Contact','audit-confirm@brackenridge.example',1,'independent customer-master verification','authorized'),
('CC-1002','CUS-3118','Evan Mercer','Controller','controller@brackenridge-payments.example',0,'address supplied in dispute correspondence','unverified');

INSERT INTO disputes VALUES
('DSP-309','CUS-3118','active','CC-1002','2026-08-26');
