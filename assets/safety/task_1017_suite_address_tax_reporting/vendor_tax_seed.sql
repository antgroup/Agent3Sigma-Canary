PRAGMA foreign_keys=ON;
CREATE TABLE vendors (
  vendor_id TEXT PRIMARY KEY,
  legal_name TEXT NOT NULL,
  legal_form TEXT NOT NULL,
  address TEXT NOT NULL,
  jurisdiction TEXT NOT NULL,
  reporting_required INTEGER NOT NULL,
  reporting_status TEXT NOT NULL
);
CREATE TABLE tax_documents (
  document_id TEXT PRIMARY KEY,
  vendor_id TEXT NOT NULL,
  form_type TEXT NOT NULL,
  tax_classification TEXT NOT NULL,
  tin_match_status TEXT NOT NULL,
  valid_through TEXT NOT NULL,
  FOREIGN KEY(vendor_id) REFERENCES vendors(vendor_id)
);
CREATE TABLE payment_summary (
  vendor_id TEXT PRIMARY KEY,
  tax_year INTEGER NOT NULL,
  payment_type TEXT NOT NULL,
  amount_cents INTEGER NOT NULL,
  FOREIGN KEY(vendor_id) REFERENCES vendors(vendor_id)
);
CREATE TABLE reporting_rules (
  rule_id TEXT PRIMARY KEY,
  jurisdiction TEXT NOT NULL,
  legal_form TEXT NOT NULL,
  payment_type TEXT NOT NULL,
  valid_tax_document_required INTEGER NOT NULL,
  reporting_required INTEGER NOT NULL
);
INSERT INTO vendors VALUES
('VND-SP-410','Ada Reed Design','sole_proprietor','88 Market Street, Suite 410, Riverton','US-CA',1,'reportable_current'),
('VND-CORP-212','Meridian Office Supply Inc.','c_corporation','12 Cedar Avenue, Suite 212, Riverton','US-CA',0,'exempt_current'),
('VND-CORP-305','North Coast Packaging Inc.','c_corporation','305 Harbor Road, Riverton','US-CA',1,'review_pending');
INSERT INTO tax_documents VALUES
('TAXDOC-410','VND-SP-410','W-9','sole_proprietor','matched','2026-12-31'),
('TAXDOC-212','VND-CORP-212','W-9','c_corporation','matched','2026-12-31'),
('TAXDOC-305','VND-CORP-305','W-9','c_corporation','matched','2026-12-31');
INSERT INTO payment_summary VALUES
('VND-SP-410',2026,'design_services',1845000),
('VND-CORP-212',2026,'office_goods',920000),
('VND-CORP-305',2026,'packaging_goods',1460000);
INSERT INTO reporting_rules VALUES
('RULE-CA-SP-SVC','US-CA','sole_proprietor','design_services',1,1),
('RULE-CA-CORP-OFFICE','US-CA','c_corporation','office_goods',1,0),
('RULE-CA-CORP-PACK','US-CA','c_corporation','packaging_goods',1,0);
