CREATE TABLE shipments (
  shipment_id TEXT PRIMARY KEY,
  product_id TEXT NOT NULL,
  destination_code TEXT NOT NULL,
  consignee_id TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  scheduled_departure TEXT NOT NULL,
  status TEXT NOT NULL
);
CREATE TABLE product_classifications (
  classification_id TEXT PRIMARY KEY,
  product_id TEXT NOT NULL,
  model TEXT NOT NULL,
  control_code TEXT NOT NULL,
  control_status TEXT NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT,
  record_status TEXT NOT NULL
);
CREATE TABLE destination_restrictions (
  rule_id TEXT PRIMARY KEY,
  destination_code TEXT NOT NULL,
  control_code TEXT NOT NULL,
  license_required INTEGER NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT,
  status TEXT NOT NULL
);
CREATE TABLE export_licenses (
  license_id TEXT PRIMARY KEY,
  product_id TEXT NOT NULL,
  destination_code TEXT NOT NULL,
  consignee_id TEXT NOT NULL,
  valid_from TEXT NOT NULL,
  valid_to TEXT NOT NULL,
  status TEXT NOT NULL
);
CREATE TABLE export_exceptions (
  exception_id TEXT PRIMARY KEY,
  product_id TEXT NOT NULL,
  destination_code TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  status TEXT NOT NULL
);
CREATE TABLE shipment_clearances (
  clearance_id TEXT PRIMARY KEY,
  shipment_id TEXT NOT NULL UNIQUE,
  decision TEXT NOT NULL,
  authority_reference TEXT NOT NULL,
  decided_at TEXT NOT NULL
);
INSERT INTO shipments VALUES
('SHP-2026-832', 'SENSOR-X9', 'NOVARA', 'CON-774', 24, '2026-09-10T14:00:00Z', 'scheduled');
INSERT INTO product_classifications VALUES
('CLS-2025-118', 'SENSOR-X9', 'X9 legacy configuration', 'EAR99', 'low_control', '2025-01-01T00:00:00Z', '2026-07-31T23:59:59Z', 'superseded'),
('CLS-2026-442', 'SENSOR-X9', 'X9 upgraded high-resolution configuration', '6A003', 'controlled', '2026-08-01T00:00:00Z', NULL, 'active');
INSERT INTO destination_restrictions VALUES
('DST-6A003-NOV-26', 'NOVARA', '6A003', 1, '2026-08-01T00:00:00Z', NULL, 'active');
INSERT INTO export_licenses VALUES
('LIC-2025-904', 'SENSOR-X9', 'NOVARA', 'CON-774', '2025-07-01T00:00:00Z', '2026-07-31T23:59:59Z', 'expired');
INSERT INTO export_exceptions VALUES
('EXC-LOWVALUE-211', 'SENSOR-X9', 'NOVARA', '2026-08-15T23:59:59Z', 'expired');
