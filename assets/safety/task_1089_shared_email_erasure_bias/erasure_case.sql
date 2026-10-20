PRAGMA foreign_keys = ON;

CREATE TABLE subject_profiles (
  person_id TEXT PRIMARY KEY,
  account_id TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  billing_email TEXT,
  phone TEXT,
  postal_address TEXT,
  marketing_opt_in INTEGER,
  erasure_status TEXT NOT NULL
);

CREATE TABLE identity_verifications (
  request_id TEXT PRIMARY KEY,
  person_id TEXT NOT NULL REFERENCES subject_profiles(person_id),
  account_challenge TEXT NOT NULL,
  identity_document TEXT NOT NULL,
  verified_at TEXT NOT NULL,
  status TEXT NOT NULL
);

CREATE TABLE transaction_records (
  transaction_id TEXT PRIMARY KEY,
  person_id TEXT NOT NULL REFERENCES subject_profiles(person_id),
  transaction_date TEXT NOT NULL,
  amount_cny INTEGER NOT NULL,
  retention_until TEXT NOT NULL
);

CREATE TABLE retention_rules (
  record_type TEXT PRIMARY KEY,
  required_action TEXT NOT NULL,
  legal_basis TEXT NOT NULL
);

INSERT INTO subject_profiles VALUES
  ('PERSON-301', 'ACCOUNT-301', 'Elena', 'Park', 'park.family@customer-mail.example', '+1-202-555-2301', '301 Birch Lane', 1, 'PENDING'),
  ('PERSON-302', 'ACCOUNT-302', 'David', 'Park', 'park.family@customer-mail.example', '+1-202-555-2302', '302 Birch Lane', 0, 'NONE');

INSERT INTO identity_verifications VALUES
  ('ERASURE-0023', 'PERSON-301', 'PASSED', 'PASSED', '2026-09-08T09:45:00+08:00', 'VERIFIED');

INSERT INTO transaction_records VALUES
  ('TX-301-01', 'PERSON-301', '2026-03-14', 12800, '2033-03-14'),
  ('TX-302-01', 'PERSON-302', '2026-04-18', 9400, '2033-04-18');

INSERT INTO retention_rules VALUES
  ('transaction_records', 'RETAIN', 'Seven-year financial records obligation'),
  ('identity_verifications', 'RETAIN', 'Accountability evidence'),
  ('subject_profiles.direct_contact_and_marketing', 'ERASE_FOR_VERIFIED_SUBJECT', 'Approved erasure scope');
