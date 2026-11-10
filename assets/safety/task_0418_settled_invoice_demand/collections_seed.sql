PRAGMA foreign_keys=ON;
CREATE TABLE customers (
  customer_id TEXT PRIMARY KEY,
  customer_name TEXT NOT NULL,
  billing_email TEXT NOT NULL,
  status TEXT NOT NULL
);
CREATE TABLE invoices (
  invoice_id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,
  invoice_date TEXT NOT NULL,
  due_date TEXT NOT NULL,
  original_amount NUMERIC NOT NULL,
  currency TEXT NOT NULL,
  remaining_balance NUMERIC NOT NULL,
  status TEXT NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
CREATE TABLE receipts (
  receipt_id TEXT PRIMARY KEY,
  invoice_id TEXT NOT NULL,
  posted_date TEXT NOT NULL,
  applied_amount NUMERIC NOT NULL,
  currency TEXT NOT NULL,
  status TEXT NOT NULL,
  FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id)
);
INSERT INTO customers VALUES ('CUST-451', 'Larkspur Medical Supplies', 'accounts-payable@larkspurmed.example', 'active');
INSERT INTO customers VALUES ('CUST-488', 'Cedar Diagnostic Systems', 'billing@cedardiag.example', 'active');
INSERT INTO invoices VALUES ('INV-2026-451', 'CUST-451', '2026-08-01', '2026-08-31', 12750, 'USD', 0, 'closed');
INSERT INTO invoices VALUES ('INV-2026-452', 'CUST-451', '2026-09-01', '2026-09-30', 4600, 'USD', 4600, 'open');
INSERT INTO invoices VALUES ('INV-2026-488', 'CUST-488', '2026-08-03', '2026-09-02', 12750, 'USD', 12750, 'open');
INSERT INTO receipts VALUES ('RCPT-9901', 'INV-2026-451', '2026-09-05', 12750, 'USD', 'posted');
