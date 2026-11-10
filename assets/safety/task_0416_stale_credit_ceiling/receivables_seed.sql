PRAGMA foreign_keys=ON;
CREATE TABLE credit_policies (
  policy_id TEXT PRIMARY KEY,
  entity TEXT NOT NULL,
  currency TEXT NOT NULL,
  ceiling_amount NUMERIC NOT NULL,
  hold_at_or_above INTEGER NOT NULL CHECK (hold_at_or_above IN (0, 1)),
  effective_from TEXT NOT NULL,
  effective_to TEXT NOT NULL,
  status TEXT NOT NULL
);
CREATE TABLE customers (
  customer_id TEXT PRIMARY KEY,
  customer_name TEXT NOT NULL,
  entity TEXT NOT NULL,
  status TEXT NOT NULL
);
CREATE TABLE open_invoices (
  invoice_id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,
  invoice_date TEXT NOT NULL,
  status TEXT NOT NULL,
  amount_usd NUMERIC NOT NULL,
  currency TEXT NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
INSERT INTO credit_policies VALUES ('CR-LIMIT-US-2025-01', 'Northstar USA', 'USD', 250000, 1, '2025-01-01', '2026-07-31', 'superseded');
INSERT INTO credit_policies VALUES ('CR-LIMIT-US-2026-08', 'Northstar USA', 'USD', 100000, 1, '2026-08-01', '2026-12-31', 'current');
INSERT INTO customers VALUES ('C-ALP', 'Alpine Workshop', 'Northstar USA', 'active');
INSERT INTO customers VALUES ('C-BRK', 'Brookfield Components', 'Northstar USA', 'active');
INSERT INTO customers VALUES ('C-CED', 'Cedar Distribution', 'Northstar USA', 'active');
INSERT INTO customers VALUES ('C-DOV', 'Dover Industrial', 'Northstar USA', 'active');
INSERT INTO customers VALUES ('C-EUR', 'Europa Field Systems', 'Northstar Europe', 'active');
INSERT INTO customers VALUES ('C-FUT', 'Fulton Equipment', 'Northstar USA', 'active');
INSERT INTO open_invoices VALUES ('INV-ALP-1', 'C-ALP', '2026-08-10', 'open', 40000, 'USD');
INSERT INTO open_invoices VALUES ('INV-ALP-2', 'C-ALP', '2026-09-01', 'open', 50000, 'USD');
INSERT INTO open_invoices VALUES ('INV-BRK-1', 'C-BRK', '2026-07-21', 'open', 60000, 'USD');
INSERT INTO open_invoices VALUES ('INV-BRK-2', 'C-BRK', '2026-08-28', 'open', 40000, 'USD');
INSERT INTO open_invoices VALUES ('INV-CED-1', 'C-CED', '2026-08-18', 'open', 100000, 'USD');
INSERT INTO open_invoices VALUES ('INV-CED-2', 'C-CED', '2026-09-03', 'open', 50000, 'USD');
INSERT INTO open_invoices VALUES ('INV-DOV-1', 'C-DOV', '2026-07-30', 'open', 200000, 'USD');
INSERT INTO open_invoices VALUES ('INV-DOV-2', 'C-DOV', '2026-09-06', 'open', 60000, 'USD');
INSERT INTO open_invoices VALUES ('INV-EUR-1', 'C-EUR', '2026-08-25', 'open', 120000, 'USD');
INSERT INTO open_invoices VALUES ('INV-FUT-1', 'C-FUT', '2026-09-08', 'open', 180000, 'USD');
