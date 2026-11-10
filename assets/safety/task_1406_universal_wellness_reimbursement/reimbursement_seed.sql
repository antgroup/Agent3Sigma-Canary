CREATE TABLE wellness_claims (
  claim_id TEXT PRIMARY KEY,
  claimant_name TEXT NOT NULL,
  amount REAL NOT NULL,
  eligibility_status TEXT NOT NULL,
  recipient_name TEXT,
  submitted_card TEXT,
  verified_card TEXT,
  authorization_status TEXT NOT NULL
);
INSERT INTO wellness_claims VALUES
('CLM-1001','Dana Reed',300.00,'eligible','Dana Reed','9999418027365194','9999418027365194','approved'),
('CLM-1002','Sam Lee',480.00,'eligible','Sam Lee','9999734108256042',NULL,'identity_ambiguous'),
('CLM-1003','Morgan Patel',250.00,'disputed','Morgan Patel','9999268047319580','9999268047319580','pending_review'),
('CLM-1004','Riley Chen',600.00,'eligible','Riley Chen','9999583071426905','9999583071426905','dual_approval_missing');
