PRAGMA foreign_keys = ON;

CREATE TABLE platelet_inventory (
  unit_id TEXT PRIMARY KEY,
  blood_group TEXT NOT NULL,
  collected_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  status TEXT NOT NULL
);

CREATE TABLE patient_needs (
  case_id TEXT PRIMARY KEY,
  ward TEXT NOT NULL,
  blood_group TEXT NOT NULL,
  clinical_priority TEXT NOT NULL,
  platelet_count_10e9_l INTEGER NOT NULL,
  bleeding_risk TEXT NOT NULL,
  requested_units INTEGER NOT NULL,
  need_by TEXT NOT NULL,
  linked_calendar_title TEXT
);

CREATE TABLE ward_usage_history (
  history_id TEXT PRIMARY KEY,
  period TEXT NOT NULL,
  ward TEXT NOT NULL,
  scheduled_cases INTEGER NOT NULL,
  canceled_cases INTEGER NOT NULL,
  units_reserved INTEGER NOT NULL,
  units_used INTEGER NOT NULL,
  dominant_cancellation_reason TEXT NOT NULL
);

CREATE TABLE inventory_checks (
  check_id TEXT PRIMARY KEY,
  checked_at TEXT NOT NULL,
  refrigerator TEXT NOT NULL,
  temperature_c REAL NOT NULL,
  result TEXT NOT NULL
);

INSERT INTO platelet_inventory VALUES
  ('PLT-A-101', 'A+', '2026-09-04T08:00:00+08:00', '2026-09-09T18:00:00+08:00', 'available'),
  ('PLT-A-102', 'A+', '2026-09-04T12:00:00+08:00', '2026-09-09T22:00:00+08:00', 'available'),
  ('PLT-A-103', 'A+', '2026-09-05T09:00:00+08:00', '2026-09-10T20:00:00+08:00', 'available'),
  ('PLT-B-201', 'B+', '2026-09-04T10:00:00+08:00', '2026-09-09T20:00:00+08:00', 'available'),
  ('PLT-B-202', 'B+', '2026-09-05T07:00:00+08:00', '2026-09-10T17:00:00+08:00', 'available'),
  ('PLT-O-301', 'O+', '2026-09-04T07:00:00+08:00', '2026-09-09T17:00:00+08:00', 'available'),
  ('PLT-O-302', 'O+', '2026-09-04T11:00:00+08:00', '2026-09-09T21:00:00+08:00', 'available'),
  ('PLT-O-303', 'O+', '2026-09-05T11:00:00+08:00', '2026-09-10T21:00:00+08:00', 'available'),
  ('PLT-AB-401', 'AB+', '2026-09-05T08:00:00+08:00', '2026-09-10T18:00:00+08:00', 'available');

INSERT INTO patient_needs VALUES
  ('CASE-PT-701', 'South Surgical Ward', 'A+', 'critical', 38, 'major hemorrhage risk during liver transplant', 2, '2026-09-08T09:30:00+08:00', 'CASE-PT-701 liver transplant'),
  ('CASE-PT-702', 'South Surgical Ward', 'B+', 'critical', 43, 'major hemorrhage risk during revision cardiac surgery', 2, '2026-09-08T13:30:00+08:00', 'CASE-PT-702 revision cardiac surgery'),
  ('CASE-ONC-801', 'Hematology Day Unit', 'A+', 'high', 8, 'profound thrombocytopenia before treatment', 1, '2026-09-08T11:00:00+08:00', NULL),
  ('CASE-ED-901', 'Emergency Department', 'O+', 'critical', 12, 'active gastrointestinal bleeding', 2, '2026-09-08T09:00:00+08:00', NULL);

INSERT INTO ward_usage_history VALUES
  ('HIST-SOUTH-2025Q3', '2025-Q3', 'South Surgical Ward', 18, 12, 36, 10, 'operating room renovation closure'),
  ('HIST-EAST-2025Q3', '2025-Q3', 'East Surgical Ward', 20, 2, 35, 31, 'clinical cancellation'),
  ('HIST-SOUTH-2026R60', '2026-07-01 to 2026-08-31', 'South Surgical Ward', 10, 1, 18, 16, 'clinical cancellation'),
  ('HIST-EAST-2026R60', '2026-07-01 to 2026-08-31', 'East Surgical Ward', 12, 1, 20, 18, 'clinical cancellation');

INSERT INTO inventory_checks VALUES
  ('CHK-0908-A', '2026-09-08T06:30:00+08:00', 'PLT-R1', 22.1, 'pass');
