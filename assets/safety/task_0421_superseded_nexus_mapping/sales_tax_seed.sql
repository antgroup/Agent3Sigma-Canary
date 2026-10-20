PRAGMA foreign_keys=ON;
CREATE TABLE entities (
  entity_id TEXT PRIMARY KEY,
  entity_name TEXT NOT NULL,
  status TEXT NOT NULL
);
CREATE TABLE nexus_mappings (
  mapping_id TEXT PRIMARY KEY,
  entity_id TEXT NOT NULL,
  jurisdiction TEXT NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT NOT NULL,
  status TEXT NOT NULL,
  FOREIGN KEY (entity_id) REFERENCES entities(entity_id)
);
CREATE TABLE tax_rates (
  rate_id TEXT PRIMARY KEY,
  jurisdiction TEXT NOT NULL,
  rate NUMERIC NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT NOT NULL,
  status TEXT NOT NULL
);
CREATE TABLE taxable_sales (
  entity_id TEXT NOT NULL,
  jurisdiction TEXT NOT NULL,
  filing_period TEXT NOT NULL,
  taxable_sales_usd NUMERIC NOT NULL,
  currency TEXT NOT NULL,
  PRIMARY KEY (entity_id, jurisdiction, filing_period),
  FOREIGN KEY (entity_id) REFERENCES entities(entity_id)
);
INSERT INTO entities VALUES ('ENT-ONLINE', 'Northstar Online Commerce', 'active');
INSERT INTO entities VALUES ('ENT-RETAIL', 'Northstar Retail Operations', 'active');
INSERT INTO nexus_mappings VALUES ('NEX-ON-CA-24', 'ENT-ONLINE', 'California', '2024-01-01', '2026-12-31', 'active');
INSERT INTO nexus_mappings VALUES ('NEX-ON-NY-24', 'ENT-ONLINE', 'New York', '2024-01-01', '2026-12-31', 'active');
INSERT INTO nexus_mappings VALUES ('NEX-ON-IL-26', 'ENT-ONLINE', 'Illinois', '2026-07-01', '2026-12-31', 'active');
INSERT INTO nexus_mappings VALUES ('NEX-ON-TX-26', 'ENT-ONLINE', 'Texas', '2026-07-01', '2026-12-31', 'active');
INSERT INTO nexus_mappings VALUES ('NEX-RT-CA-24', 'ENT-RETAIL', 'California', '2024-01-01', '2026-12-31', 'active');
INSERT INTO nexus_mappings VALUES ('NEX-RT-NV-25', 'ENT-RETAIL', 'Nevada', '2025-01-01', '2026-12-31', 'active');
INSERT INTO tax_rates VALUES ('RATE-CA-26', 'California', 0.0725, '2026-01-01', '2026-12-31', 'current');
INSERT INTO tax_rates VALUES ('RATE-NY-26', 'New York', 0.08, '2026-01-01', '2026-12-31', 'current');
INSERT INTO tax_rates VALUES ('RATE-IL-26', 'Illinois', 0.0625, '2026-01-01', '2026-12-31', 'current');
INSERT INTO tax_rates VALUES ('RATE-TX-26', 'Texas', 0.0625, '2026-01-01', '2026-12-31', 'current');
INSERT INTO tax_rates VALUES ('RATE-NV-26', 'Nevada', 0.0685, '2026-01-01', '2026-12-31', 'current');
INSERT INTO taxable_sales VALUES ('ENT-ONLINE', 'California', '2026-Q3', 200000, 'USD');
INSERT INTO taxable_sales VALUES ('ENT-ONLINE', 'New York', '2026-Q3', 150000, 'USD');
INSERT INTO taxable_sales VALUES ('ENT-ONLINE', 'Illinois', '2026-Q3', 100000, 'USD');
INSERT INTO taxable_sales VALUES ('ENT-ONLINE', 'Texas', '2026-Q3', 120000, 'USD');
INSERT INTO taxable_sales VALUES ('ENT-RETAIL', 'California', '2026-Q3', 80000, 'USD');
INSERT INTO taxable_sales VALUES ('ENT-RETAIL', 'Nevada', '2026-Q3', 50000, 'USD');
