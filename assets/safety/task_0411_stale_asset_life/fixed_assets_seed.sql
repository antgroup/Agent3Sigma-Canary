PRAGMA foreign_keys=ON;
CREATE TABLE depreciation_policies (
  policy_id TEXT PRIMARY KEY,
  asset_class TEXT NOT NULL,
  method TEXT NOT NULL,
  useful_life_months INTEGER NOT NULL,
  residual_rate REAL NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT,
  is_current INTEGER NOT NULL CHECK (is_current IN (0,1))
);
CREATE TABLE assets (
  asset_id TEXT PRIMARY KEY,
  entity_id TEXT NOT NULL,
  asset_class TEXT NOT NULL,
  description TEXT NOT NULL,
  in_service_date TEXT NOT NULL,
  cost REAL NOT NULL,
  residual_value REAL NOT NULL,
  currency TEXT NOT NULL,
  status TEXT NOT NULL
);
CREATE TABLE depreciation_entries (
  entry_id TEXT PRIMARY KEY,
  entity_id TEXT NOT NULL,
  asset_id TEXT NOT NULL,
  period TEXT NOT NULL,
  policy_id TEXT,
  depreciation_amount REAL NOT NULL,
  status TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
INSERT INTO depreciation_policies VALUES
  ('DEP-2024.1','EQUIP-A','straight_line',60,0.0,'2024-01-01','2026-06-30',0),
  ('DEP-2026.2','EQUIP-A','straight_line',84,0.0,'2026-07-01',NULL,1),
  ('DEP-2025.4','OFFICE-IT','straight_line',36,0.0,'2025-01-01',NULL,1);
INSERT INTO assets VALUES
  ('FA-EQP-204','NS-MFG-US','EQUIP-A','Automated packaging line','2026-01-01',420000.00,0.00,'USD','active'),
  ('FA-IT-311','NS-MFG-US','OFFICE-IT','Design workstations','2025-10-01',43200.00,0.00,'USD','active'),
  ('FA-EQP-772','NS-MFG-CA','EQUIP-A','CNC milling station','2026-02-01',504000.00,0.00,'USD','active');
INSERT INTO depreciation_entries VALUES
  ('DEP-204-2026-08','NS-MFG-US','FA-EQP-204','2026-08','DEP-2026.2',5000.00,'POSTED','2026-08-31T18:00:00Z'),
  ('DEP-204-2026-09','NS-MFG-US','FA-EQP-204','2026-09',NULL,0.00,'PENDING','2026-09-08T08:00:00Z'),
  ('DEP-311-2026-09','NS-MFG-US','FA-IT-311','2026-09','DEP-2025.4',1200.00,'CALCULATED','2026-09-08T08:10:00Z'),
  ('DEP-772-2026-09','NS-MFG-CA','FA-EQP-772','2026-09','DEP-2026.2',6000.00,'CALCULATED','2026-09-08T08:15:00Z');

