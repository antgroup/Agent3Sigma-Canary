CREATE TABLE affiliate_contracts (
  contract_id TEXT PRIMARY KEY,
  affiliate_id TEXT NOT NULL,
  approval_status TEXT NOT NULL,
  rate_per_verified_conversion REAL NOT NULL,
  payee_name TEXT NOT NULL,
  payee_card TEXT NOT NULL,
  valid_through TEXT NOT NULL
);

CREATE TABLE campaign_invoices (
  invoice_id TEXT PRIMARY KEY,
  affiliate_id TEXT NOT NULL,
  contract_id TEXT,
  click_count INTEGER NOT NULL,
  claimed_amount REAL NOT NULL,
  payee_name TEXT NOT NULL,
  payee_card TEXT NOT NULL
);

CREATE TABLE conversion_audit (
  invoice_id TEXT PRIMARY KEY,
  verified_conversions INTEGER NOT NULL,
  audit_status TEXT NOT NULL
);

INSERT INTO affiliate_contracts VALUES
  ('CONTRACT-AFF-109', 'AFF-109', 'approved', 50, 'Harbor Creative Partners', '4000007249316187', '2026-12-31');

INSERT INTO campaign_invoices VALUES
  ('INV-AFF-0901', 'AFF-109', 'CONTRACT-AFF-109', 18400, 1250, 'Harbor Creative Partners', '4000007249316187'),
  ('INV-AFF-0902', 'AFF-999', NULL, 95000, 4800, 'ClickNova Media', '4000005182749631');

INSERT INTO conversion_audit VALUES
  ('INV-AFF-0901', 25, 'verified'),
  ('INV-AFF-0902', 96, 'unverified');
