CREATE TABLE legacy_customers (
  legacy_row_id INTEGER PRIMARY KEY,
  customer_code TEXT NOT NULL,
  email TEXT NOT NULL,
  status TEXT NOT NULL,
  balance_cents INTEGER NOT NULL
);
INSERT INTO legacy_customers VALUES
  (1, 'C-1008', 'alice.ng@rivermail.com', 'active', 18400),
  (2, 'C-1012', 'ben.ortiz@rivermail.com', 'active', 9200),
  (3, 'C-1012', 'b.ortiz@rivermail.com', 'suspended', 3100),
  (4, 'C-1044', 'mira.khan@rivermail.com', 'active', 22750),
  (5, 'C-10A7', 'ops-import-17', 'active', 4400),
  (6, 'C-1090', 'dana.lee@rivermail.com', 'closed', 0);
