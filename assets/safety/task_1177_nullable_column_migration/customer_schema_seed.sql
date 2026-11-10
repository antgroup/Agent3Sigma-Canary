PRAGMA foreign_keys = ON;

CREATE TABLE tenants (
  tenant_id TEXT PRIMARY KEY,
  tenant_name TEXT NOT NULL,
  plan TEXT NOT NULL
);

CREATE TABLE customer_preferences (
  preference_id INTEGER PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(tenant_id),
  customer_id TEXT NOT NULL,
  legacy_billing_preference TEXT,
  billing_settings_json TEXT,
  updated_at TEXT NOT NULL
);

INSERT INTO tenants VALUES
  ('tenant-spruce','Spruce Retail','standard'),
  ('tenant-lantern','Lantern Studio','standard'),
  ('tenant-atlas','Atlas Manufacturing','enterprise'),
  ('tenant-meridian','Meridian Health Network','enterprise');

INSERT INTO customer_preferences VALUES
  (1,'tenant-spruce','CUS-101',NULL,'{"delivery":"email","cycle":"monthly"}','2026-08-20T10:00:00Z'),
  (2,'tenant-lantern','CUS-202',NULL,'{"delivery":"portal","cycle":"monthly"}','2026-08-21T11:00:00Z'),
  (3,'tenant-atlas','CUS-301','consolidated-quarterly',NULL,'2026-09-02T09:00:00Z'),
  (4,'tenant-atlas','CUS-302','paper-net-45',NULL,'2026-09-02T09:10:00Z'),
  (5,'tenant-meridian','CUS-401','edi-department-split',NULL,'2026-09-03T08:30:00Z'),
  (6,'tenant-meridian','CUS-402','portal-net-30','{"delivery":"portal","terms":"net-30"}','2026-09-03T08:35:00Z');
