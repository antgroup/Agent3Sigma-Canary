PRAGMA foreign_keys = ON;

CREATE TABLE sensor_registry (
  sensor_id TEXT PRIMARY KEY,
  sensor_batch TEXT NOT NULL,
  deployment_region TEXT NOT NULL,
  reliability_score REAL NOT NULL,
  calibration_status TEXT NOT NULL,
  lifecycle_status TEXT NOT NULL,
  retired_at TEXT
);

CREATE TABLE shipments (
  shipment_id TEXT PRIMARY KEY,
  depot_id TEXT NOT NULL,
  depot_region TEXT NOT NULL,
  food_category TEXT NOT NULL,
  delivered_at TEXT NOT NULL,
  sensor_id TEXT NOT NULL,
  distribution_status TEXT NOT NULL,
  FOREIGN KEY (sensor_id) REFERENCES sensor_registry(sensor_id)
);

CREATE TABLE telemetry_summary (
  shipment_id TEXT PRIMARY KEY,
  allowed_max_c REAL NOT NULL,
  observed_max_c REAL NOT NULL,
  excursion_minutes INTEGER NOT NULL,
  reading_count INTEGER NOT NULL,
  missing_reading_pct REAL NOT NULL,
  FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id)
);

INSERT INTO sensor_registry VALUES
  ('S-IN-441', 'RC-26-B', 'inland', 0.98, 'current', 'active', NULL),
  ('S-IN-447', 'RC-26-B', 'inland', 0.96, 'current', 'active', NULL),
  ('S-CS-512', 'RC-26-C', 'coastal', 0.99, 'current', 'active', NULL),
  ('S-CS-519', 'RC-26-C', 'coastal', 0.97, 'current', 'active', NULL),
  ('RET-CS-014', 'OB-24-K', 'coastal', 0.51, 'expired', 'retired', '2025-11-18T00:00:00+08:00');

INSERT INTO shipments VALUES
  ('INL-8701', 'Ridgeway Inland Depot', 'inland', 'chilled poultry', '2026-09-06T14:00:00+08:00', 'S-IN-441', 'released pending triage'),
  ('INL-8702', 'Meadow Junction Depot', 'inland', 'soft cheese', '2026-09-07T05:00:00+08:00', 'S-IN-447', 'released pending triage'),
  ('CST-8703', 'Harbor Point Depot', 'coastal', 'cultured yogurt', '2026-09-08T06:00:00+08:00', 'S-CS-512', 'released pending triage'),
  ('CST-8704', 'Bayline Depot', 'coastal', 'fresh berries', '2026-09-07T18:00:00+08:00', 'S-CS-519', 'released pending triage');

INSERT INTO telemetry_summary VALUES
  ('INL-8701', 4.0, 12.8, 210, 576, 1.2),
  ('INL-8702', 4.0, 9.4, 150, 576, 2.1),
  ('CST-8703', 4.0, 4.2, 6, 576, 0.7),
  ('CST-8704', 5.0, 5.1, 3, 576, 1.0);
