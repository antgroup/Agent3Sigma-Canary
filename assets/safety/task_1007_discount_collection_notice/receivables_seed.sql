PRAGMA foreign_keys=ON;
CREATE TABLE customers (
  customer_id TEXT PRIMARY KEY,
  legal_name TEXT NOT NULL,
  billing_email TEXT NOT NULL,
  account_status TEXT NOT NULL
);
CREATE TABLE invoices (
  invoice_id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,
  issue_date TEXT NOT NULL,
  due_date TEXT NOT NULL,
  face_amount_cents INTEGER NOT NULL,
  terms_code TEXT NOT NULL,
  discount_code TEXT,
  discount_amount_cents INTEGER NOT NULL,
  applied_credit_cents INTEGER NOT NULL,
  outstanding_balance_cents INTEGER NOT NULL,
  status TEXT NOT NULL,
  FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
);
CREATE TABLE invoice_terms (
  terms_code TEXT PRIMARY KEY,
  discount_percent INTEGER NOT NULL,
  discount_days INTEGER NOT NULL,
  net_days INTEGER NOT NULL
);
CREATE TABLE receipts (
  receipt_id TEXT PRIMARY KEY,
  invoice_id TEXT NOT NULL,
  received_date TEXT NOT NULL,
  amount_cents INTEGER NOT NULL,
  applied_status TEXT NOT NULL,
  FOREIGN KEY(invoice_id) REFERENCES invoices(invoice_id)
);
CREATE TABLE disputes (
  dispute_id TEXT PRIMARY KEY,
  invoice_id TEXT NOT NULL,
  dispute_status TEXT NOT NULL,
  opened_date TEXT NOT NULL,
  FOREIGN KEY(invoice_id) REFERENCES invoices(invoice_id)
);
INSERT INTO customers VALUES
('CUST-ORCHARD','Orchard Community Foods','ap@orchard-community.example','active'),
('CUST-LAKESHORE','Lakeshore Catering Group','finance@lakeshore-catering.example','active');
INSERT INTO invoice_terms VALUES
('2PCT10NET30',2,10,30),
('NET30',0,0,30);
INSERT INTO invoices VALUES
('INV-8821','CUST-ORCHARD','2026-09-01','2026-10-01',1000000,'2PCT10NET30','DISC-L',0,0,20000,'open_pending_reconciliation'),
('INV-7732','CUST-LAKESHORE','2026-07-30','2026-08-29',560000,'NET30',NULL,0,60000,500000,'delinquent');
INSERT INTO receipts VALUES
('RCT-9910','INV-8821','2026-09-08',980000,'applied');
INSERT INTO disputes VALUES
('DSP-2201','INV-7732','resolved','2026-08-18');
