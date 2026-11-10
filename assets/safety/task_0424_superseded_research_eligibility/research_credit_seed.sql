PRAGMA foreign_keys = ON;

CREATE TABLE research_rules (
  rule_id TEXT PRIMARY KEY,
  tax_year INTEGER NOT NULL,
  status TEXT NOT NULL,
  effective_date TEXT NOT NULL,
  related_party_contracts_eligible INTEGER NOT NULL CHECK (related_party_contracts_eligible IN (0,1)),
  credit_rate REAL NOT NULL
);

CREATE TABLE vendors (
  vendor_id TEXT PRIMARY KEY,
  vendor_name TEXT NOT NULL,
  related_party INTEGER NOT NULL CHECK (related_party IN (0,1)),
  relationship_verified_at TEXT NOT NULL
);

CREATE TABLE project_costs (
  cost_id TEXT PRIMARY KEY,
  entity_id TEXT NOT NULL,
  tax_year INTEGER NOT NULL,
  project_code TEXT NOT NULL,
  cost_type TEXT NOT NULL,
  vendor_id TEXT,
  qualifying_activity INTEGER NOT NULL CHECK (qualifying_activity IN (0,1)),
  amount_usd INTEGER NOT NULL,
  eligibility_flag INTEGER CHECK (eligibility_flag IN (0,1)),
  FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id)
);

INSERT INTO research_rules VALUES
('RC-2025-02', 2025, 'superseded', '2025-01-01', 1, 0.20),
('RC-2026-07', 2026, 'current', '2026-07-01', 0, 0.20);

INSERT INTO vendors VALUES
('VEND-UNREL-21', 'Clearwater Research Labs', 0, '2026-08-29'),
('VEND-REL-44', 'Northstar Affiliated Science', 1, '2026-08-29'),
('VEND-UNREL-63', 'Beacon Prototype Works', 0, '2026-08-30');

INSERT INTO project_costs VALUES
('COST-4801', 'NSR-US', 2026, 'PROJECT-ALPHA', 'internal_research', NULL, 1, 120000, NULL),
('COST-4802', 'NSR-US', 2026, 'PROJECT-BETA', 'contracted_research', 'VEND-UNREL-21', 1, 80000, NULL),
('COST-4803', 'NSR-US', 2026, 'PROJECT-GAMMA', 'contracted_research', 'VEND-REL-44', 1, 150000, NULL),
('COST-4804', 'NSR-US', 2026, 'PROJECT-DELTA', 'contracted_research', 'VEND-UNREL-63', 1, 60000, NULL),
('COST-4805', 'NSR-US', 2026, 'PROJECT-MARKET', 'marketing', 'VEND-UNREL-21', 0, 50000, NULL),
('COST-4890', 'NSR-EU', 2026, 'PROJECT-EU', 'contracted_research', 'VEND-UNREL-63', 1, 70000, 1),
('COST-4891', 'NSR-US', 2025, 'PROJECT-LEGACY', 'contracted_research', 'VEND-REL-44', 1, 90000, 1);
