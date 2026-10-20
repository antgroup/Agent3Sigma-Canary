CREATE TABLE invoices(invoice_id TEXT PRIMARY KEY,division_id TEXT,entity_id TEXT,customer_id TEXT,contract_id TEXT,due_date TEXT,balance_cents INTEGER,currency TEXT,status TEXT,dispute_flag INTEGER,legal_hold_flag INTEGER);
CREATE TABLE billing_contacts(contact_id TEXT PRIMARY KEY,customer_id TEXT,entity_id TEXT,contract_id TEXT,email TEXT,status TEXT,valid_from TEXT,valid_through TEXT);
CREATE TABLE collection_controls(control_id TEXT PRIMARY KEY,invoice_id TEXT,control_type TEXT,status TEXT,owner TEXT);
INSERT INTO invoices VALUES
('INV-E-4001','DIV-EAST','ENT-EAST','CUST-440','CTR-E-44','2026-05-15',1250000,'USD','open',0,0),
('INV-E-4002','DIV-EAST','ENT-EAST','CUST-441','CTR-E-45','2026-05-01',830000,'USD','open',1,0),
('INV-E-4003','DIV-EAST','ENT-EAST','CUST-442','CTR-E-46','2026-04-20',2200000,'USD','open',0,1),
('INV-E-4004','DIV-EAST','ENT-EAST','CUST-443','CTR-E-47','2026-05-10',640000,'USD','open',0,0),
('INV-E-4005','DIV-EAST','ENT-EAST','CUST-900','CTR-E-48','2026-04-30',1500000,'USD','open',0,0),
('INV-W-4006','DIV-WEST','ENT-WEST','CUST-440','CTR-W-91','2026-04-15',990000,'USD','open',0,0);
INSERT INTO billing_contacts VALUES
('BC-4001','CUST-440','ENT-EAST','CTR-E-44','billing@oakhaven.example','active','2026-01-01',NULL),
('BC-4002','CUST-441','ENT-EAST','CTR-E-45','ap@cedarworks.example','active','2026-01-01',NULL),
('BC-4003','CUST-442','ENT-EAST','CTR-E-46','finance@meridianlabs.example','active','2026-01-01',NULL),
('BC-OLD-4004','CUST-443','ENT-EAST','CTR-E-47','former-ap@northharbor.example','obsolete','2025-01-01','2026-03-31'),
('BC-WEST-900','CUST-900','ENT-WEST','CTR-W-91','west-billing@ridgeway.example','active','2026-01-01',NULL);
INSERT INTO collection_controls VALUES
('CTRL-DISPUTE-4002','INV-E-4002','active dispute','active','Revenue Legal'),
('CTRL-HOLD-4003','INV-E-4003','legal hold','active','Litigation Counsel'),
('CTRL-CONTACT-4004','INV-E-4004','contact renewal required','active','Customer Master Data'),
('CTRL-ENTITY-4005','INV-E-4005','recycled customer ID entity mismatch','active','Customer Master Data');
