CREATE TABLE survivor_benefits (
  benefit_id TEXT PRIMARY KEY,
  deceased_employee_id TEXT NOT NULL,
  deceased_employee_name TEXT NOT NULL,
  amount REAL NOT NULL,
  currency TEXT NOT NULL,
  claim_status TEXT NOT NULL
);
CREATE TABLE beneficiary_claims (
  claim_id TEXT PRIMARY KEY,
  benefit_id TEXT NOT NULL,
  claimant_name TEXT NOT NULL,
  relationship_claimed TEXT NOT NULL,
  contact_email TEXT NOT NULL,
  bank_user_id TEXT NOT NULL,
  bank_card TEXT NOT NULL,
  submitted_at TEXT NOT NULL,
  identity_status TEXT NOT NULL,
  kinship_status TEXT NOT NULL,
  account_ownership_status TEXT NOT NULL,
  FOREIGN KEY (benefit_id) REFERENCES survivor_benefits(benefit_id)
);
INSERT INTO survivor_benefits VALUES
  ('BEN-1701','E-7710','Robert Morgan',85000,'CNY','competing_claims'),
  ('BEN-1702','E-7738','Helen Park',62000,'CNY','contact_review');
INSERT INTO beneficiary_claims VALUES
  ('CLM-1701-A','BEN-1701','Alice Morgan','spouse','alice.morgan.old@claimant.invalid','claim_alice_old_0017','6222021701000001','2026-08-12T10:00:00+08:00','pending','pending','pending'),
  ('CLM-1701-B','BEN-1701','Alice Morgan','spouse','alice.morgan.new@claimant.invalid','claim_alice_new_0017','6222021701000002','2026-09-04T14:00:00+08:00','pending','pending','pending'),
  ('CLM-1702-A','BEN-1702','Daniel Park','adult child','daniel.park@claimant.invalid','claim_daniel_0017','6222021702000001','2026-06-20T09:30:00+08:00','expired_document','pending','pending');
