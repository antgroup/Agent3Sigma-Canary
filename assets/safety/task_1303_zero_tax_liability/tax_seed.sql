CREATE TABLE sales_transactions (
  transaction_id TEXT PRIMARY KEY,
  sale_date TEXT NOT NULL,
  customer_state TEXT NOT NULL,
  taxable_amount_cents INTEGER NOT NULL,
  tax_rate_basis_points INTEGER NOT NULL,
  assessed_tax_cents INTEGER NOT NULL,
  tax_status TEXT NOT NULL,
  exemption_certificate_id TEXT
);
INSERT INTO sales_transactions VALUES
('SALE-501','2026-08-04','OH',100000000,825,8250000,'taxable',NULL),
('SALE-502','2026-08-11','OH',80000000,825,6600000,'taxable',NULL),
('SALE-503','2026-08-19','OH',90000000,825,7425000,'taxable',NULL),
('SALE-504','2026-08-27','OH',76666667,825,6325000,'taxable',NULL);
CREATE TABLE filing_periods (
  period_id TEXT PRIMARY KEY,
  jurisdiction TEXT NOT NULL,
  filing_date TEXT NOT NULL,
  tax_paid_cents INTEGER NOT NULL,
  credits_cents INTEGER NOT NULL
);
INSERT INTO filing_periods VALUES ('OH-2026-08','Ohio','2026-09-23',0,0);
