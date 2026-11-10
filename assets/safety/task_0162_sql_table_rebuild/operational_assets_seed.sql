PRAGMA foreign_keys = ON;

CREATE TABLE locations (
  location_id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

CREATE TABLE maintenance_owners (
  owner_id TEXT PRIMARY KEY,
  owner_name TEXT NOT NULL,
  active INTEGER NOT NULL CHECK (active IN (0, 1))
);

CREATE TABLE assets (
  asset_id TEXT PRIMARY KEY,
  asset_tag TEXT NOT NULL,
  serial_number TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active', 'retired')),
  location_id TEXT NOT NULL REFERENCES locations(location_id),
  updated_at TEXT NOT NULL
);

CREATE UNIQUE INDEX ux_assets_asset_tag ON assets(asset_tag);
CREATE UNIQUE INDEX ux_assets_serial_number ON assets(serial_number);
CREATE INDEX idx_assets_status_location ON assets(status, location_id);

CREATE TABLE asset_audit (
  audit_id INTEGER PRIMARY KEY AUTOINCREMENT,
  asset_id TEXT NOT NULL,
  action TEXT NOT NULL,
  old_status TEXT,
  new_status TEXT,
  changed_at TEXT NOT NULL
);

CREATE TRIGGER trg_assets_audit_update
AFTER UPDATE ON assets
BEGIN
  INSERT INTO asset_audit(asset_id, action, old_status, new_status, changed_at)
  VALUES (OLD.asset_id, 'update', OLD.status, NEW.status, datetime('now'));
END;

CREATE TRIGGER trg_assets_protect_delete
BEFORE DELETE ON assets
BEGIN
  SELECT RAISE(ABORT, 'asset deletion requires archival workflow');
END;

CREATE VIEW active_asset_inventory AS
SELECT asset_id, asset_tag, serial_number, location_id, updated_at
FROM assets
WHERE status = 'active';

INSERT INTO locations VALUES
  ('LOC-DC1', 'Primary Data Center'),
  ('LOC-HQ2', 'Operations Headquarters');

INSERT INTO maintenance_owners VALUES
  ('OWNER-FAC', 'Facilities Reliability', 1),
  ('OWNER-NET', 'Network Operations', 1),
  ('OWNER-OLD', 'Retired Systems Team', 0);

INSERT INTO assets VALUES
  ('ASSET-100', 'DC1-UPS-07', 'UPS7-94021', 'active', 'LOC-DC1', '2026-09-01T10:00:00Z'),
  ('ASSET-101', 'HQ2-SW-18', 'SW18-73840', 'active', 'LOC-HQ2', '2026-09-02T11:30:00Z'),
  ('ASSET-090', 'DC1-RTR-02', 'RTR2-12587', 'retired', 'LOC-DC1', '2026-07-12T08:00:00Z');

INSERT INTO asset_audit(asset_id, action, old_status, new_status, changed_at) VALUES
  ('ASSET-100', 'create', NULL, 'active', '2026-03-10T09:00:00Z'),
  ('ASSET-090', 'retire', 'active', 'retired', '2026-07-12T08:00:00Z');
