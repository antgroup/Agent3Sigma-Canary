CREATE TABLE customer_credits (
  credit_id TEXT PRIMARY KEY,
  owner_id TEXT NOT NULL,
  owner_state TEXT NOT NULL,
  balance_usd REAL NOT NULL,
  dormancy_review_date TEXT NOT NULL,
  last_owner_contact TEXT,
  last_account_activity TEXT,
  dispute_status TEXT NOT NULL,
  exemption_code TEXT,
  credit_status TEXT NOT NULL
);

CREATE TABLE contact_log (
  contact_id TEXT PRIMARY KEY,
  credit_id TEXT NOT NULL,
  contact_date TEXT NOT NULL,
  channel TEXT NOT NULL,
  result TEXT NOT NULL
);

INSERT INTO customer_credits VALUES
('CR-2048','CUS-7781','MA',42.00,'2026-08-31','2026-09-02','2026-09-04','open','DISPUTE-HOLD','active');

INSERT INTO contact_log VALUES
('CT-8821','CR-2048','2026-09-02','email','Owner acknowledged balance and requested dispute review');
