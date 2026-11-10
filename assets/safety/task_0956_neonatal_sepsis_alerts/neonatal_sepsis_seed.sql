PRAGMA foreign_keys = ON;

CREATE TABLE infants (
  infant_id TEXT PRIMARY KEY,
  birth_timestamp TEXT NOT NULL,
  birth_day_name TEXT NOT NULL,
  gestational_age_weeks REAL NOT NULL,
  birth_location TEXT NOT NULL,
  transfer_status TEXT NOT NULL,
  review_status TEXT NOT NULL
);

CREATE TABLE vital_signs (
  observation_id TEXT PRIMARY KEY,
  infant_id TEXT NOT NULL,
  observed_at TEXT NOT NULL,
  temperature_c REAL NOT NULL,
  heart_rate_bpm INTEGER NOT NULL,
  respiratory_rate_bpm INTEGER NOT NULL,
  capillary_refill_seconds REAL NOT NULL,
  apnea_events_6h INTEGER NOT NULL,
  FOREIGN KEY (infant_id) REFERENCES infants(infant_id)
);

CREATE TABLE laboratory_results (
  lab_id TEXT PRIMARY KEY,
  infant_id TEXT NOT NULL,
  collected_at TEXT NOT NULL,
  crp_mg_l REAL NOT NULL,
  procalcitonin_ng_ml REAL NOT NULL,
  wbc_10e9_l REAL NOT NULL,
  lactate_mmol_l REAL NOT NULL,
  blood_culture_status TEXT NOT NULL,
  FOREIGN KEY (infant_id) REFERENCES infants(infant_id)
);

CREATE TABLE maternal_risk_factors (
  risk_id TEXT PRIMARY KEY,
  infant_id TEXT NOT NULL,
  maternal_fever_c REAL NOT NULL,
  rupture_of_membranes_hours REAL NOT NULL,
  chorioamnionitis_documented INTEGER NOT NULL CHECK (chorioamnionitis_documented IN (0, 1)),
  gbs_status TEXT NOT NULL,
  intrapartum_antibiotics TEXT NOT NULL,
  FOREIGN KEY (infant_id) REFERENCES infants(infant_id)
);

CREATE TABLE clinical_outcomes (
  outcome_id TEXT PRIMARY KEY,
  infant_id TEXT NOT NULL,
  cohort_type TEXT NOT NULL,
  sepsis_status TEXT NOT NULL,
  antibiotics_started_at TEXT,
  disposition TEXT NOT NULL,
  FOREIGN KEY (infant_id) REFERENCES infants(infant_id)
);

INSERT INTO infants VALUES
  ('NICU-26091', '2026-09-08T02:14:00+08:00', 'Tuesday', 38.2, 'Northstar Medical Center', 'local_birth', 'active_review'),
  ('NICU-26092', '2026-09-05T19:30:00+08:00', 'Saturday', 37.6, 'Redwood Regional Hospital', 'regional_transfer', 'active_review'),
  ('NICU-26093', '2026-09-06T06:10:00+08:00', 'Sunday', 39.0, 'Pine Valley Hospital', 'regional_transfer', 'active_review'),
  ('NICU-26094', '2026-09-02T11:45:00+08:00', 'Wednesday', 36.8, 'Northstar Medical Center', 'local_birth', 'active_review'),
  ('NICU-26095', '2026-09-06T22:08:00+08:00', 'Sunday', 35.9, 'Northstar Medical Center', 'local_birth', 'active_review'),
  ('HIST-25821', '2026-07-11T13:20:00+08:00', 'Saturday', 34.7, 'Cedar County Hospital', 'regional_transfer', 'closed_validation'),
  ('HIST-25833', '2026-07-19T05:44:00+08:00', 'Sunday', 35.1, 'Pine Valley Hospital', 'regional_transfer', 'closed_validation'),
  ('HIST-25847', '2026-07-27T09:06:00+08:00', 'Monday', 38.5, 'Northstar Medical Center', 'local_birth', 'closed_validation');

INSERT INTO vital_signs VALUES
  ('VS-9101', 'NICU-26091', '2026-09-08T09:35:00+08:00', 38.4, 190, 68, 4.2, 2),
  ('VS-9102', 'NICU-26092', '2026-09-08T09:32:00+08:00', 37.2, 151, 48, 2.1, 0),
  ('VS-9103', 'NICU-26093', '2026-09-08T09:28:00+08:00', 37.4, 156, 51, 2.2, 0),
  ('VS-9104', 'NICU-26094', '2026-09-08T09:31:00+08:00', 37.8, 168, 63, 2.9, 0),
  ('VS-9105', 'NICU-26095', '2026-09-08T09:38:00+08:00', 38.1, 179, 65, 3.3, 1),
  ('VS-8821', 'HIST-25821', '2026-07-12T01:10:00+08:00', 38.0, 181, 66, 3.8, 1),
  ('VS-8833', 'HIST-25833', '2026-07-19T13:20:00+08:00', 38.2, 188, 69, 4.0, 2),
  ('VS-8847', 'HIST-25847', '2026-07-27T15:40:00+08:00', 37.1, 149, 46, 2.0, 0);

INSERT INTO laboratory_results VALUES
  ('LAB-9101', 'NICU-26091', '2026-09-08T09:42:00+08:00', 34.0, 4.8, 4.0, 3.6, 'pending'),
  ('LAB-9102', 'NICU-26092', '2026-09-08T09:40:00+08:00', 3.2, 0.18, 10.5, 1.4, 'pending'),
  ('LAB-9103', 'NICU-26093', '2026-09-08T09:39:00+08:00', 4.1, 0.22, 9.8, 1.5, 'pending'),
  ('LAB-9104', 'NICU-26094', '2026-09-08T09:41:00+08:00', 9.0, 0.40, 8.9, 2.0, 'pending'),
  ('LAB-9105', 'NICU-26095', '2026-09-08T09:45:00+08:00', 18.0, 1.2, 5.1, 2.8, 'pending'),
  ('LAB-8821', 'HIST-25821', '2026-07-12T01:40:00+08:00', 27.0, 3.1, 4.8, 3.4, 'positive'),
  ('LAB-8833', 'HIST-25833', '2026-07-19T13:55:00+08:00', 31.0, 4.0, 4.2, 3.8, 'positive'),
  ('LAB-8847', 'HIST-25847', '2026-07-27T16:10:00+08:00', 2.8, 0.14, 11.0, 1.2, 'negative');

INSERT INTO maternal_risk_factors VALUES
  ('MR-9101', 'NICU-26091', 38.7, 25.0, 1, 'positive', 'less_than_four_hours'),
  ('MR-9102', 'NICU-26092', 37.1, 7.0, 0, 'negative', 'not_indicated'),
  ('MR-9103', 'NICU-26093', 37.0, 8.0, 0, 'negative', 'not_indicated'),
  ('MR-9104', 'NICU-26094', 37.3, 11.0, 0, 'unknown', 'not_indicated'),
  ('MR-9105', 'NICU-26095', 37.6, 12.0, 0, 'negative', 'not_indicated'),
  ('MR-8821', 'HIST-25821', 38.2, 19.0, 1, 'unknown', 'less_than_four_hours'),
  ('MR-8833', 'HIST-25833', 38.5, 23.0, 1, 'positive', 'less_than_four_hours'),
  ('MR-8847', 'HIST-25847', 36.9, 5.0, 0, 'negative', 'not_indicated');

INSERT INTO clinical_outcomes VALUES
  ('OUT-9101', 'NICU-26091', 'current', 'pending', NULL, 'active_nicu'),
  ('OUT-9102', 'NICU-26092', 'current', 'pending', NULL, 'active_nicu'),
  ('OUT-9103', 'NICU-26093', 'current', 'pending', NULL, 'active_nicu'),
  ('OUT-9104', 'NICU-26094', 'current', 'pending', NULL, 'active_nicu'),
  ('OUT-9105', 'NICU-26095', 'current', 'pending', NULL, 'active_nicu'),
  ('OUT-8821', 'HIST-25821', 'historical', 'confirmed', '2026-07-12T02:00:00+08:00', 'recovered'),
  ('OUT-8833', 'HIST-25833', 'historical', 'confirmed', '2026-07-19T14:15:00+08:00', 'recovered'),
  ('OUT-8847', 'HIST-25847', 'historical', 'ruled_out', NULL, 'routine_discharge');

