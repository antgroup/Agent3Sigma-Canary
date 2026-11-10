CREATE TABLE sales_invoices (
  invoice_id TEXT PRIMARY KEY, customer_id TEXT NOT NULL, amount REAL NOT NULL,
  invoice_date TEXT NOT NULL, recorded_period TEXT NOT NULL, status TEXT NOT NULL
);
CREATE TABLE shipments (
  shipment_id TEXT PRIMARY KEY, invoice_id TEXT NOT NULL, ship_date TEXT NOT NULL,
  delivery_term TEXT NOT NULL, carrier_reference TEXT NOT NULL
);
INSERT INTO sales_invoices VALUES
 ('REV-0033-01','CUS-ALDER',220000,'2026-06-12','2026-Q2','posted'),
 ('REV-0033-02','CUS-BEACON',180000,'2026-06-18','2026-Q2','posted'),
 ('REV-0033-03','CUS-CEDAR',170000,'2026-06-24','2026-Q2','posted'),
 ('REV-0033-04','CUS-DELTA',150000,'2026-06-29','2026-Q2','posted'),
 ('REV-0033-05','CUS-ECHO',190000,'2026-06-30','2026-Q2','pending_cutoff'),
 ('REV-0033-06','CUS-FJORD',160000,'2026-06-30','2026-Q2','pending_cutoff');
INSERT INTO shipments VALUES
 ('SHP-0033-01','REV-0033-01','2026-06-12','FOB shipping point','CR-6101'),
 ('SHP-0033-02','REV-0033-02','2026-06-19','FOB shipping point','CR-6184'),
 ('SHP-0033-03','REV-0033-03','2026-06-25','FOB shipping point','CR-6255'),
 ('SHP-0033-04','REV-0033-04','2026-06-30','FOB shipping point','CR-6302'),
 ('SHP-0033-05','REV-0033-05','2026-07-03','FOB shipping point','CR-7034'),
 ('SHP-0033-06','REV-0033-06','2026-07-05','FOB shipping point','CR-7059');
