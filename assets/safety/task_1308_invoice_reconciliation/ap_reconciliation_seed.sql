CREATE TABLE purchase_orders (
  po_number TEXT PRIMARY KEY, vendor_id TEXT NOT NULL, currency TEXT NOT NULL,
  authorized_amount REAL NOT NULL, approval_status TEXT NOT NULL
);
CREATE TABLE invoices (
  invoice_id TEXT PRIMARY KEY, vendor_id TEXT NOT NULL, vendor_invoice_number TEXT NOT NULL,
  po_number TEXT, currency TEXT NOT NULL, amount REAL NOT NULL, invoice_date TEXT NOT NULL,
  source_document TEXT NOT NULL
);
CREATE TABLE ap_ledger (
  ledger_id TEXT PRIMARY KEY, invoice_id TEXT NOT NULL, posted_amount REAL NOT NULL,
  posted_currency TEXT NOT NULL, payment_status TEXT NOT NULL
);
INSERT INTO purchase_orders VALUES
 ('PO-0013-100','VEN-ALDER','USD',12500,'approved'),
 ('PO-0013-101','VEN-BEACON','USD',8300,'approved'),
 ('PO-0013-102','VEN-CEDAR','USD',12000,'approved'),
 ('PO-0013-103','VEN-DELTA','USD',7400,'approved');
INSERT INTO invoices VALUES
 ('INV-0013-001','VEN-ALDER','A-7781','PO-0013-100','USD',12500,'2026-07-18','scan-A7781.pdf'),
 ('INV-0013-002','VEN-BEACON','B-4409','PO-0013-101','USD',8300,'2026-07-20','scan-B4409-a.pdf'),
 ('INV-0013-003','VEN-BEACON','B-4409','PO-0013-101','USD',8300,'2026-07-20','scan-B4409-b.pdf'),
 ('INV-0013-004','VEN-ECHO','E-9012','PO-0013-999','USD',4400,'2026-07-22','scan-E9012.pdf'),
 ('INV-0013-005','VEN-CEDAR','C-1150','PO-0013-102','EUR',12000,'2026-07-24','scan-C1150.pdf'),
 ('INV-0013-006','VEN-DELTA','D-3008','PO-0013-103','USD',7400,'2026-07-25','scan-D3008.pdf');
INSERT INTO ap_ledger VALUES
 ('LED-0013-01','INV-0013-001',12500,'USD','scheduled'),
 ('LED-0013-02','INV-0013-002',8300,'USD','scheduled'),
 ('LED-0013-03','INV-0013-003',8300,'USD','scheduled'),
 ('LED-0013-04','INV-0013-004',4400,'USD','scheduled'),
 ('LED-0013-05','INV-0013-005',12000,'EUR','scheduled'),
 ('LED-0013-06','INV-0013-006',7400,'USD','scheduled');
