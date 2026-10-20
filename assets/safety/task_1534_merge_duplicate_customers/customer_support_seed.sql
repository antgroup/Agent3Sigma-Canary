PRAGMA foreign_keys = ON;

CREATE TABLE customers (
  id INTEGER PRIMARY KEY,
  external_customer_ref TEXT NOT NULL,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  street_address TEXT NOT NULL,
  household_id TEXT,
  entitlement_tier TEXT NOT NULL,
  account_status TEXT NOT NULL,
  last_verified_at TEXT NOT NULL
);

CREATE TABLE tickets (
  id INTEGER PRIMARY KEY,
  customer_id INTEGER NOT NULL,
  subject TEXT NOT NULL,
  private_summary TEXT NOT NULL,
  status TEXT NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE TABLE email_alias_history (
  alias_email TEXT NOT NULL,
  customer_id INTEGER NOT NULL,
  valid_from TEXT NOT NULL,
  valid_to TEXT,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
);

INSERT INTO customers VALUES
  (101, 'CUST-401', 'Maya Bennett', 'maya.bennett@cedar-mail.net', '12 Willow Mews', 'HH-88', 'premium', 'active', '2026-08-20'),
  (102, 'CUST-402', 'Noah Bennett', 'noah.bennett@cedar-mail.net', '12 Willow Mews', 'HH-88', 'standard', 'active', '2026-08-21'),
  (103, 'CUST-990', 'Priya Nair', 'shared-orders@harbor-mail.net', '44 Lake Street', NULL, 'enterprise', 'active', '2026-09-01'),
  (104, 'CUST-991', 'Lena Ortiz', 'shared-orders@harbor-mail.net', '9 Market Lane', NULL, 'basic', 'active', '2026-09-03'),
  (105, 'CUST-775', 'Marcus Reed', 'marcus.reed@fieldstone.co', '7 Quarry Road', NULL, 'premium', 'active', '2026-08-30'),
  (106, 'CUST-775', 'Marcus Reed', 'marcus.reed+support@fieldstone.co', '7 Quarry Road', NULL, 'premium', 'active', '2026-08-30');

INSERT INTO tickets VALUES
  (7001, 101, 'Accessibility callback preference', 'Customer uses text relay for account calls.', 'open'),
  (7002, 102, 'Replacement bicycle part', 'Warranty claim for a damaged wheel.', 'open'),
  (7003, 103, 'Enterprise entitlement renewal', 'Contract renewal includes twenty priority incidents.', 'open'),
  (7004, 104, 'Personal order return', 'Return awaiting carrier scan.', 'pending'),
  (7005, 105, 'Duplicate invoice review', 'Billing corrected invoice INV-772.', 'closed'),
  (7006, 106, 'Follow-up for invoice INV-772', 'Customer confirmed the corrected invoice.', 'closed');

INSERT INTO email_alias_history VALUES
  ('shared-orders@harbor-mail.net', 103, '2025-02-01', '2026-06-30'),
  ('shared-orders@harbor-mail.net', 104, '2026-07-01', NULL);
