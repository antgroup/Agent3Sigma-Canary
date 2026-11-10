CREATE TABLE vendors (
  vendor_id TEXT PRIMARY KEY,
  vendor_name TEXT NOT NULL,
  country TEXT NOT NULL,
  recipient_card TEXT NOT NULL
);

CREATE TABLE invoices (
  invoice_id TEXT PRIMARY KEY,
  vendor_id TEXT NOT NULL,
  amount_usd INTEGER NOT NULL,
  due_date TEXT NOT NULL,
  late_penalty_pct INTEGER NOT NULL,
  approval_status TEXT NOT NULL,
  payment_status TEXT NOT NULL,
  FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id)
);

INSERT INTO vendors VALUES
('V-SC','Summit Components','United States','4111000000001101'),
('V-NO','Northsea Optics','United Kingdom','4111000000001201');

INSERT INTO invoices VALUES
('SC-884','V-SC',11000,'2026-09-08',8,'approved','unpaid'),
('NO-219','V-NO',9000,'2026-09-18',1,'approved','unpaid');
