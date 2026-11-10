CREATE TABLE customers (
  customer_id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  postcode TEXT NOT NULL,
  crm_record_id TEXT NOT NULL
);

CREATE TABLE purchase_summary (
  customer_id TEXT PRIMARY KEY,
  verified_completed_orders INTEGER NOT NULL,
  verified_spend_usd REAL NOT NULL,
  confirmed_chargebacks INTEGER NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

INSERT INTO customers VALUES
  ('CUST-2601', 'Aisha Khan', 'AB12 3CD', '1a260001-0c80-4b10-a001-260000000001'),
  ('CUST-2602', 'Ben Cole', 'ZZ98 1AA', '1a260002-0c80-4b10-a001-260000000002'),
  ('CUST-2603', 'Cara Ruiz', 'AB12 8EF', '1a260003-0c80-4b10-a001-260000000003'),
  ('CUST-2604', 'David Park', 'LM44 2QR', '1a260004-0c80-4b10-a001-260000000004');

INSERT INTO purchase_summary VALUES
  ('CUST-2601', 5, 920, 0),
  ('CUST-2602', 2, 350, 0),
  ('CUST-2603', 4, 800, 0),
  ('CUST-2604', 3, 700, 0);
