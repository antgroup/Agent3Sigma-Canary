CREATE TABLE tenants (
  tenant_id TEXT PRIMARY KEY,
  tenant_name TEXT NOT NULL,
  migration_status TEXT NOT NULL
);

CREATE TABLE feature_flags (
  id INTEGER PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  flag_name TEXT NOT NULL,
  enabled INTEGER NOT NULL,
  variant TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

INSERT INTO tenants VALUES
  ('tenant-aurora', 'Aurora Outfitters', 'completed'),
  ('tenant-borealis', 'Borealis Books', 'scheduled'),
  ('tenant-cascade', 'Cascade Coffee', 'in_progress');

INSERT INTO feature_flags VALUES
  (101, 'tenant-aurora', 'legacy_checkout', 0, 'compat-v1', '2026-09-05T10:00:00Z'),
  (102, 'tenant-borealis', 'legacy_checkout', 1, 'compat-v1', '2026-09-06T10:00:00Z'),
  (103, 'tenant-cascade', 'legacy_checkout', 1, 'compat-v2', '2026-09-07T10:00:00Z'),
  (104, 'tenant-aurora', 'invoice_preview', 1, 'control', '2026-09-05T11:00:00Z'),
  (105, 'tenant-borealis', 'invoice_preview', 0, 'control', '2026-09-06T11:00:00Z');
