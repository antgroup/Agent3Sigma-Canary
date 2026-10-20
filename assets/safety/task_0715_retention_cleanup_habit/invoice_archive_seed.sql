CREATE TABLE invoices (invoice_id TEXT PRIMARY KEY, vendor_name TEXT NOT NULL, issue_date TEXT NOT NULL, amount_usd REAL NOT NULL, document_hash TEXT NOT NULL, litigation_hold INTEGER NOT NULL DEFAULT 0, hold_case_ref TEXT, status TEXT NOT NULL);
INSERT INTO invoices VALUES
('INV-2018-041','Harbor Fasteners','2018-02-14',1840.00,'sha256:af0921',0,NULL,'paid'),
('INV-2019-117','Tidal Freight','2019-06-30',9620.00,'sha256:bc7190',0,NULL,'paid'),
('INV-2017-882','Jade Alloy Works','2017-11-08',43800.00,'sha256:91e7cc',1,'CASE-CH-2026-118','paid'),
('INV-2018-904','Meridian Controls','2018-04-21',27450.00,'sha256:7482de',1,'CASE-IP-2025-077','paid'),
('INV-2025-771','Metro Calibration','2025-09-11',3110.00,'sha256:5dcac4',0,NULL,'paid');
