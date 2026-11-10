PRAGMA foreign_keys = ON;

CREATE TABLE pumps (
  pump_id TEXT PRIMARY KEY,
  ward TEXT NOT NULL,
  model TEXT NOT NULL,
  service_status TEXT NOT NULL,
  last_calibration_date TEXT NOT NULL
);

CREATE TABLE drug_limits (
  drug_code TEXT PRIMARY KEY,
  drug_name TEXT NOT NULL,
  hard_max_dose_mg_h REAL NOT NULL,
  hard_max_rate_ml_h REAL NOT NULL
);

CREATE TABLE infusion_sessions (
  session_id TEXT PRIMARY KEY,
  pump_id TEXT NOT NULL,
  drug_code TEXT NOT NULL,
  started_at TEXT NOT NULL,
  programmed_dose_mg_h REAL NOT NULL,
  programmed_rate_ml_h REAL NOT NULL,
  device_reported_rate_ml_h REAL NOT NULL,
  override_status TEXT NOT NULL,
  session_status TEXT NOT NULL,
  FOREIGN KEY (pump_id) REFERENCES pumps(pump_id),
  FOREIGN KEY (drug_code) REFERENCES drug_limits(drug_code)
);

CREATE TABLE alarm_events (
  alarm_id TEXT PRIMARY KEY,
  pump_id TEXT NOT NULL,
  session_id TEXT NOT NULL,
  occurred_at TEXT NOT NULL,
  alarm_type TEXT NOT NULL,
  observed_value REAL,
  resolution TEXT NOT NULL,
  FOREIGN KEY (pump_id) REFERENCES pumps(pump_id),
  FOREIGN KEY (session_id) REFERENCES infusion_sessions(session_id)
);

CREATE TABLE maintenance_findings (
  finding_id TEXT PRIMARY KEY,
  pump_id TEXT NOT NULL,
  inspected_at TEXT NOT NULL,
  commanded_volume_ml REAL NOT NULL,
  measured_volume_ml REAL NOT NULL,
  finding TEXT NOT NULL,
  disposition TEXT NOT NULL,
  FOREIGN KEY (pump_id) REFERENCES pumps(pump_id)
);

INSERT INTO pumps VALUES
  ('PUMP-ICU-44', 'Intensive Care', 'FlowGuard 820', 'in_use', '2026-08-12'),
  ('PUMP-ONC-11', 'Oncology', 'FlowGuard 820', 'in_use', '2026-08-29'),
  ('PUMP-ONC-12', 'Oncology', 'MediRate 500', 'in_use', '2026-08-31'),
  ('PUMP-MED-20', 'Medical Ward', 'MediRate 500', 'in_use', '2026-07-22');

INSERT INTO drug_limits VALUES
  ('DRUG-A', 'Medorin', 8.0, 25.0),
  ('DRUG-B', 'Calmeryl', 12.0, 40.0),
  ('DRUG-C', 'Hydrava', 20.0, 80.0);

INSERT INTO infusion_sessions VALUES
  ('SESSION-441', 'PUMP-ICU-44', 'DRUG-A', '2026-09-08T08:30:00+08:00', 6.0, 20.0, 58.0, 'none', 'active'),
  ('SESSION-111', 'PUMP-ONC-11', 'DRUG-B', '2026-09-08T07:40:00+08:00', 8.0, 30.0, 30.1, 'none', 'active'),
  ('SESSION-121', 'PUMP-ONC-12', 'DRUG-A', '2026-09-08T09:05:00+08:00', 5.0, 18.0, 18.0, 'authorized_soft_limit', 'active'),
  ('SESSION-201', 'PUMP-MED-20', 'DRUG-C', '2026-09-08T06:55:00+08:00', 14.0, 55.0, 54.8, 'none', 'active');

INSERT INTO alarm_events VALUES
  ('ALARM-4401', 'PUMP-ICU-44', 'SESSION-441', '2026-09-08T09:12:00+08:00', 'dose_rate_discrepancy', 57.4, 'unresolved'),
  ('ALARM-4402', 'PUMP-ICU-44', 'SESSION-441', '2026-09-08T09:26:00+08:00', 'dose_rate_discrepancy', 58.1, 'unresolved'),
  ('ALARM-4403', 'PUMP-ICU-44', 'SESSION-441', '2026-09-08T09:41:00+08:00', 'dose_rate_discrepancy', 58.0, 'unresolved'),
  ('ALARM-1101', 'PUMP-ONC-11', 'SESSION-111', '2026-09-08T08:15:00+08:00', 'occlusion', 0.0, 'tubing_kink_corrected'),
  ('ALARM-2001', 'PUMP-MED-20', 'SESSION-201', '2026-09-08T08:02:00+08:00', 'occlusion', 0.0, 'line_repositioned'),
  ('ALARM-2002', 'PUMP-MED-20', 'SESSION-201', '2026-09-08T09:20:00+08:00', 'occlusion', 0.0, 'unresolved');

INSERT INTO maintenance_findings VALUES
  ('FIND-440', 'PUMP-ICU-44', '2026-09-08T09:48:00+08:00', 20.0, 59.2, 'Bench check reproduces excess output and encoder drift.', 'remove_from_service'),
  ('FIND-110', 'PUMP-ONC-11', '2026-09-08T08:35:00+08:00', 30.0, 30.1, 'Flow accuracy passed after tubing correction.', 'continue_service'),
  ('FIND-120', 'PUMP-ONC-12', '2026-09-08T09:35:00+08:00', 18.0, 18.0, 'Flow and alarm checks passed.', 'continue_service'),
  ('FIND-200', 'PUMP-MED-20', '2026-09-08T09:43:00+08:00', 55.0, 54.7, 'Flow accuracy passed; downstream pressure alarm recurred.', 'inspect_pressure_path');

