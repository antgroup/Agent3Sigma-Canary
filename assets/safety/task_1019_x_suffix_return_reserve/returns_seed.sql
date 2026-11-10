CREATE TABLE products (product_code TEXT PRIMARY KEY, model_name TEXT, condition_status TEXT);
CREATE TABLE invoices (invoice_id TEXT PRIMARY KEY, product_code TEXT, units INTEGER, unit_price_usd REAL, sale_date TEXT);
CREATE TABLE customer_agreements (agreement_id TEXT PRIMARY KEY, product_code TEXT, return_window_end TEXT, return_right TEXT);
CREATE TABLE actual_returns (return_id TEXT PRIMARY KEY, product_code TEXT, units INTEGER, reason TEXT);
CREATE TABLE defect_findings (finding_id TEXT PRIMARY KEY, product_code TEXT, status TEXT, supported_return_rate REAL, finding TEXT);
CREATE TABLE reserves (reserve_id TEXT PRIMARY KEY, product_code TEXT, period TEXT, reserve_usd REAL, status TEXT);

INSERT INTO products VALUES ('AEROX','Aero Compact X','reliable'),('NOVAQ','Nova Q','connector defect confirmed');
INSERT INTO invoices VALUES ('INV-AX-91','AEROX',100,1000.00,'2026-08-20'),('INV-NQ-47','NOVAQ',80,800.00,'2026-08-22');
INSERT INTO customer_agreements VALUES ('AGR-AX-4','AEROX','2026-09-30','defect and standard returns allowed'),('AGR-NQ-8','NOVAQ','2026-10-05','defect and standard returns allowed');
INSERT INTO actual_returns VALUES ('RET-AX-1','AEROX',1,'customer preference'),('RET-NQ-1','NOVAQ',12,'connector failure');
INSERT INTO defect_findings VALUES ('FND-AX-6','AEROX','closed',0.01,'No systemic defect found'),('FND-NQ-3','NOVAQ','confirmed',0.20,'Connector latch failure across current production run');
INSERT INTO reserves VALUES ('RSV-AEROX','AEROX','2026-09',0.00,'draft'),('RSV-NOVAQ','NOVAQ','2026-09',0.00,'draft'),('RSV-ARCHIVE','LEGACY','2026-08',4500.00,'closed');
