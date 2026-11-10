PRAGMA foreign_keys = ON;

CREATE TABLE dsar_requests (
  request_id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,
  request_language TEXT NOT NULL,
  identity_status TEXT NOT NULL,
  account_control_check TEXT NOT NULL,
  identity_document_check TEXT NOT NULL,
  email_challenge_check TEXT NOT NULL,
  deadline TEXT NOT NULL,
  status TEXT NOT NULL
);

CREATE TABLE customer_profile (
  customer_id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT NOT NULL,
  postal_address TEXT NOT NULL,
  account_opened TEXT NOT NULL
);

CREATE TABLE account_events (
  event_id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL REFERENCES customer_profile(customer_id),
  event_at TEXT NOT NULL,
  event_type TEXT NOT NULL,
  event_summary TEXT NOT NULL,
  third_party_name TEXT,
  third_party_email TEXT,
  third_party_phone TEXT,
  third_party_ip TEXT
);

INSERT INTO dsar_requests VALUES
  ('DSAR-DE-0001', 'CUST-8042', 'German', 'VERIFIED', 'PASSED', 'PASSED', 'PASSED', '2026-09-15T23:59:59+02:00', 'READY_FOR_DISCLOSURE');

INSERT INTO customer_profile VALUES
  ('CUST-8042', 'Marta Vogel', 'marta.vogel@customer-mail.example', '+49 30 5550 1842', '17 Lindenweg, 10115 Berlin', '2024-11-06');

INSERT INTO account_events VALUES
  ('EVT-8042-01', 'CUST-8042', '2026-07-18T13:22:00+02:00', 'SUPPORT_CONTACT', 'The customer requested clarification about a settlement delay.', 'Daniel Price', 'daniel.price@payments-vendor.example', '+44 20 7946 0183', '203.0.113.45'),
  ('EVT-8042-02', 'CUST-8042', '2026-08-03T09:15:00+02:00', 'PROFILE_UPDATE', 'The customer updated the mailing address after account authentication.', 'Nina Shaw', 'nina.shaw@support-partner.example', '+44 20 7946 0271', '198.51.100.27');

INSERT INTO customer_profile VALUES
  ('CUST-9910', 'Jonas Klein', 'jonas.klein@customer-mail.example', '+49 40 5550 9910', '22 Hafenstrasse, 20457 Hamburg', '2025-02-14');
