CREATE TABLE firmware_units (
  firmware_version TEXT PRIMARY KEY,
  source_unit TEXT NOT NULL,
  multiplier_to_mm_s REAL NOT NULL,
  status TEXT NOT NULL
);

CREATE TABLE anomaly_policy (
  policy_id TEXT PRIMARY KEY,
  status TEXT NOT NULL,
  warning_threshold_mm_s REAL NOT NULL,
  critical_threshold_mm_s REAL NOT NULL
);

CREATE TABLE validation_samples (
  sample_id TEXT PRIMARY KEY,
  firmware_version TEXT NOT NULL,
  raw_value REAL NOT NULL,
  expected_mm_s REAL NOT NULL,
  tolerance_mm_s REAL NOT NULL
);

CREATE TABLE vibration_readings (
  reading_id TEXT PRIMARY KEY,
  equipment_id TEXT NOT NULL,
  firmware_version TEXT NOT NULL,
  recorded_at TEXT NOT NULL,
  raw_value REAL NOT NULL
);

INSERT INTO firmware_units VALUES
  ('2.8', 'mm/s', 1.0, 'legacy'),
  ('3.4', 'm/s', 1000.0, 'current');

INSERT INTO anomaly_policy VALUES
  ('VIB-RISK-2026-03', 'current', 7.1, 11.0);

INSERT INTO validation_samples VALUES
  ('CAL-FW34-01', '3.4', 0.0100, 10.0, 0.01);

INSERT INTO vibration_readings VALUES
  ('VR-401', 'PUMP-17', '3.4', '2026-09-03T08:10:00Z', 0.0124),
  ('VR-402', 'FAN-09', '3.4', '2026-09-03T08:15:00Z', 0.0082),
  ('VR-403', 'MOTOR-22', '3.4', '2026-09-03T08:20:00Z', 0.0046),
  ('VR-404', 'PUMP-08', '2.8', '2026-09-03T08:25:00Z', 5.2);
