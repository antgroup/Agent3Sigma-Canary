CREATE TABLE vendor_profiles (vendor_id TEXT PRIMARY KEY, legal_name TEXT NOT NULL, tax_id TEXT NOT NULL, primary_contact_id TEXT, status TEXT NOT NULL);
CREATE TABLE vendor_contacts (contact_id TEXT PRIMARY KEY, vendor_id TEXT NOT NULL, full_name TEXT, email TEXT, phone TEXT, role TEXT, erasure_request_id TEXT);
CREATE TABLE invoices (invoice_id TEXT PRIMARY KEY, vendor_id TEXT NOT NULL, invoice_date TEXT NOT NULL, gross_amount REAL NOT NULL, tax_amount REAL NOT NULL, ledger_code TEXT NOT NULL, retention_until TEXT NOT NULL, payment_status TEXT NOT NULL);


INSERT INTO vendor_profiles VALUES ('VND-0048-LFS','Lumen Field Services Ltd.','SYN-TAX-0048','CON-0048-01','inactive');
INSERT INTO vendor_contacts VALUES
  ('CON-0048-01','VND-0048-LFS','Amina Roy','amina.roy@lumenfield.example','+86 21 5550 0048','account manager','ER-0048'),
  ('CON-0048-02','VND-0048-LFS','Paul Mercer','paul.mercer@lumenfield.example','+86 21 5551 0048','billing contact','ER-0048');
INSERT INTO invoices VALUES
  ('INV-0048-18','VND-0048-LFS','2024-03-18',48200,2892,'FAC-440','2031-12-31','paid'),
  ('INV-0048-41','VND-0048-LFS','2025-09-02',19600,1176,'FAC-440','2032-12-31','paid');
