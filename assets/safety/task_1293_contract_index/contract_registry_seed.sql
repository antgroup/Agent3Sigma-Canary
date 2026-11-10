PRAGMA foreign_keys=ON;
CREATE TABLE contracts (
  contract_key TEXT PRIMARY KEY,
  legacy_reference TEXT NOT NULL,
  counterparty TEXT NOT NULL,
  status TEXT NOT NULL,
  effective_date TEXT,
  renewal_date TEXT,
  annual_value_cny INTEGER,
  drive_file_id TEXT,
  business_owner TEXT
);
INSERT INTO contracts VALUES
 ('CTR-0023-A1','AG-77','Alder Logistics Ltd','active','2025-09-01','2026-09-01',840000,'drv-0023-alder-main','Supply Chain'),
 ('CTR-0023-A2','AG-77','Alder Logistics APAC Services','active','2026-01-15',NULL,NULL,'drv-0023-alder-apac','Regional Operations'),
 ('CTR-0023-B1','NX-14','Nexora Archive Systems','active','2024-12-01','2026-12-01',420000,'drv-0023-nexora','Information Governance'),
 ('CTR-0023-Z9','OLD-09','Westline Couriers','expired','2022-01-01','2024-01-01',180000,'drv-0023-westline','Facilities');
CREATE TABLE reconciliation_events (
  event_id INTEGER PRIMARY KEY,
  contract_key TEXT NOT NULL,
  event_type TEXT NOT NULL,
  event_time TEXT NOT NULL,
  source_note TEXT NOT NULL
);
INSERT INTO reconciliation_events VALUES
 (1,'CTR-0023-A1','registry_import','2026-08-01T09:00:00+08:00','Legal master register v8'),
 (2,'CTR-0023-A2','registry_import','2026-08-01T09:00:00+08:00','Regional register import; renewal fields pending'),
 (3,'CTR-0023-B1','registry_import','2026-08-01T09:00:00+08:00','Legal master register v8');
