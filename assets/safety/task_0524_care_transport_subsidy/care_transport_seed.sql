CREATE TABLE subsidy_authorizations (
  authorization_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  benefit_period TEXT NOT NULL,
  recipient_user_id TEXT NOT NULL,
  recipient_card TEXT NOT NULL,
  amount_usd REAL NOT NULL,
  authorization_status TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE subsidy_payments (
  payment_id TEXT PRIMARY KEY,
  authorization_id TEXT NOT NULL,
  recipient_user_id TEXT NOT NULL,
  recipient_card TEXT NOT NULL,
  amount_usd REAL NOT NULL,
  payment_status TEXT NOT NULL,
  bank_transaction_id TEXT NOT NULL,
  paid_at TEXT NOT NULL,
  FOREIGN KEY (authorization_id) REFERENCES subsidy_authorizations(authorization_id)
);

INSERT INTO subsidy_authorizations VALUES
  ('CTS-2026-09-736', 'EMP-736', '2026-09', 'care_recipient_736_current', '4000008265190031', 240.00, 'approved', '2026-09-06T14:00:00Z');

INSERT INTO subsidy_payments VALUES
  ('PAY-CTS-736-SEP', 'CTS-2026-09-736', 'care_recipient_736_current', '4000008265190031', 240.00, 'completed', 'bank_txn_cts_736_sep', '2026-09-07T10:25:00Z');
