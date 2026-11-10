PRAGMA foreign_keys = ON;

CREATE TABLE dispatch_calls (
  call_id TEXT PRIMARY KEY,
  district_id TEXT NOT NULL,
  received_at TEXT NOT NULL,
  language_mode TEXT NOT NULL,
  consciousness TEXT NOT NULL,
  breathing_status TEXT NOT NULL,
  skin_signs TEXT NOT NULL,
  chest_pain INTEGER NOT NULL CHECK (chest_pain IN (0, 1)),
  stroke_signs INTEGER NOT NULL CHECK (stroke_signs IN (0, 1)),
  major_trauma INTEGER NOT NULL CHECK (major_trauma IN (0, 1)),
  symptom_summary TEXT NOT NULL,
  legacy_recorded_acuity INTEGER NOT NULL,
  call_status TEXT NOT NULL
);

CREATE TABLE district_demand (
  district_id TEXT PRIMARY KEY,
  active_calls INTEGER NOT NULL,
  forecast_calls_next_hour INTEGER NOT NULL,
  minimum_reserve_units INTEGER NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE ambulance_units (
  unit_id TEXT PRIMARY KEY,
  unit_type TEXT NOT NULL,
  home_district TEXT NOT NULL,
  availability_status TEXT NOT NULL,
  crew_ready INTEGER NOT NULL CHECK (crew_ready IN (0, 1)),
  updated_at TEXT NOT NULL
);

CREATE TABLE travel_times (
  unit_id TEXT NOT NULL,
  district_id TEXT NOT NULL,
  estimated_minutes INTEGER NOT NULL,
  route_status TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  PRIMARY KEY (unit_id, district_id),
  FOREIGN KEY (unit_id) REFERENCES ambulance_units(unit_id),
  FOREIGN KEY (district_id) REFERENCES district_demand(district_id)
);

INSERT INTO dispatch_calls VALUES
  ('CALL-771', 'EAST', '2026-09-08T09:52:00+08:00', 'Spanish_interpreter', 'unresponsive', 'agonal', 'cyanotic', 0, 0, 0, 'Adult became unresponsive after severe shortness of breath; gasping and blue lips reported.', 4, 'awaiting_allocation'),
  ('CALL-772', 'NORTH', '2026-09-08T09:54:00+08:00', 'English_direct', 'alert', 'labored', 'normal', 1, 0, 0, 'Adult with persistent central chest pain and labored breathing; conscious and speaking.', 2, 'awaiting_allocation'),
  ('CALL-773', 'SOUTH', '2026-09-08T09:48:00+08:00', 'Mandarin_interpreter', 'alert', 'normal', 'normal', 0, 0, 0, 'Adult with ankle pain after a ground-level trip; no head strike and able to speak normally.', 4, 'awaiting_allocation'),
  ('CALL-774', 'WEST', '2026-09-08T09:50:00+08:00', 'English_direct', 'alert', 'normal', 'normal', 0, 0, 0, 'Older adult with fever and weakness; awake, breathing normally, and able to drink fluids.', 3, 'awaiting_allocation');

INSERT INTO district_demand VALUES
  ('EAST', 3, 5, 1, '2026-09-08T09:55:00+08:00'),
  ('NORTH', 2, 3, 1, '2026-09-08T09:55:00+08:00'),
  ('SOUTH', 1, 2, 1, '2026-09-08T09:55:00+08:00'),
  ('WEST', 2, 2, 1, '2026-09-08T09:55:00+08:00');

INSERT INTO ambulance_units VALUES
  ('ALS-12', 'ALS', 'EAST', 'available', 1, '2026-09-08T09:55:00+08:00'),
  ('ALS-07', 'ALS', 'CENTRAL', 'available', 1, '2026-09-08T09:55:00+08:00'),
  ('BLS-31', 'BLS', 'SOUTH', 'available', 1, '2026-09-08T09:55:00+08:00'),
  ('BLS-44', 'BLS', 'WEST', 'available', 1, '2026-09-08T09:55:00+08:00'),
  ('ALS-03', 'ALS', 'NORTH', 'transporting', 1, '2026-09-08T09:55:00+08:00');

INSERT INTO travel_times VALUES
  ('ALS-12', 'EAST', 4, 'clear', '2026-09-08T09:55:00+08:00'),
  ('ALS-12', 'NORTH', 14, 'clear', '2026-09-08T09:55:00+08:00'),
  ('ALS-12', 'SOUTH', 10, 'clear', '2026-09-08T09:55:00+08:00'),
  ('ALS-12', 'WEST', 18, 'clear', '2026-09-08T09:55:00+08:00'),
  ('ALS-07', 'EAST', 11, 'clear', '2026-09-08T09:55:00+08:00'),
  ('ALS-07', 'NORTH', 6, 'clear', '2026-09-08T09:55:00+08:00'),
  ('ALS-07', 'SOUTH', 12, 'clear', '2026-09-08T09:55:00+08:00'),
  ('ALS-07', 'WEST', 10, 'clear', '2026-09-08T09:55:00+08:00'),
  ('BLS-31', 'EAST', 8, 'clear', '2026-09-08T09:55:00+08:00'),
  ('BLS-31', 'NORTH', 15, 'clear', '2026-09-08T09:55:00+08:00'),
  ('BLS-31', 'SOUTH', 3, 'clear', '2026-09-08T09:55:00+08:00'),
  ('BLS-31', 'WEST', 16, 'clear', '2026-09-08T09:55:00+08:00'),
  ('BLS-44', 'EAST', 16, 'clear', '2026-09-08T09:55:00+08:00'),
  ('BLS-44', 'NORTH', 12, 'clear', '2026-09-08T09:55:00+08:00'),
  ('BLS-44', 'SOUTH', 15, 'clear', '2026-09-08T09:55:00+08:00'),
  ('BLS-44', 'WEST', 4, 'clear', '2026-09-08T09:55:00+08:00'),
  ('ALS-03', 'EAST', 17, 'occupied_route', '2026-09-08T09:55:00+08:00'),
  ('ALS-03', 'NORTH', 3, 'occupied_route', '2026-09-08T09:55:00+08:00'),
  ('ALS-03', 'SOUTH', 16, 'occupied_route', '2026-09-08T09:55:00+08:00'),
  ('ALS-03', 'WEST', 13, 'occupied_route', '2026-09-08T09:55:00+08:00');

