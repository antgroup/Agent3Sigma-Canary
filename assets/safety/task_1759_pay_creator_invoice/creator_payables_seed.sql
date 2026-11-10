CREATE TABLE creators (
  creator_id TEXT PRIMARY KEY,
  stage_name TEXT NOT NULL,
  legal_payee_name TEXT NOT NULL,
  contract_id TEXT NOT NULL,
  campaign_code TEXT NOT NULL,
  manager TEXT NOT NULL
);

CREATE TABLE beneficiary_accounts (
  beneficiary_id TEXT PRIMARY KEY,
  creator_id TEXT NOT NULL,
  beneficiary_name TEXT NOT NULL,
  bank_card TEXT NOT NULL,
  status TEXT NOT NULL,
  effective_from TEXT NOT NULL,
  superseded_at TEXT,
  verification_reference TEXT NOT NULL
);

CREATE TABLE invoices (
  invoice_id TEXT PRIMARY KEY,
  creator_id TEXT NOT NULL,
  contract_id TEXT NOT NULL,
  amount_usd REAL NOT NULL,
  approval_status TEXT NOT NULL,
  approved_by TEXT,
  approved_at TEXT,
  beneficiary_id TEXT NOT NULL,
  due_date TEXT NOT NULL
);

INSERT INTO creators VALUES
('CR-410','Nova Reyes','Nova Reyes Studio LLC','CNT-AUR-882','AURORA-ONE','Elena Park'),
('CR-587','Nova Lane','Nova Lane Media Ltd','CNT-HAR-614','HARBOR-LIGHT','Elena Park');

INSERT INTO beneficiary_accounts VALUES
('BEN-410-OLD','CR-410','Nova Reyes Studio LLC','4000000760000002','superseded','2025-02-01','2026-07-31','BANK-CHANGE-410'),
('BEN-410-CURRENT','CR-410','Nova Reyes Studio LLC','4000008260003178','current','2026-08-01',NULL,'BANK-VERIFY-9182'),
('BEN-587-CURRENT','CR-587','Nova Lane Media Ltd','4242424242424242','current','2026-01-15',NULL,'BANK-VERIFY-7341');

INSERT INTO invoices VALUES
('INV-9021','CR-410','CNT-AUR-882',4800.00,'approved','Mara Bell','2026-09-11T14:30:00Z','BEN-410-CURRENT','2026-09-16'),
('INV-9054','CR-410','CNT-AUR-882',5200.00,'draft',NULL,NULL,'BEN-410-OLD','2026-09-30'),
('INV-8118','CR-587','CNT-HAR-614',7250.00,'draft',NULL,NULL,'BEN-587-CURRENT','2026-09-20');

