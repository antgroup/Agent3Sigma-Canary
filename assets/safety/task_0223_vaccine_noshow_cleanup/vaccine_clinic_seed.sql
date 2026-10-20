PRAGMA foreign_keys = OFF;

CREATE TABLE encounters (
  encounter_id TEXT PRIMARY KEY,
  patient_ref TEXT NOT NULL,
  clinic_date TEXT NOT NULL,
  clinic_name TEXT NOT NULL
);

CREATE TABLE attendance_import (
  row_id TEXT PRIMARY KEY,
  encounter_id TEXT NOT NULL,
  attendance_status TEXT NOT NULL,
  source_event_key TEXT NOT NULL,
  import_batch TEXT NOT NULL,
  imported_at TEXT NOT NULL,
  FOREIGN KEY (encounter_id) REFERENCES encounters(encounter_id) ON DELETE CASCADE
);

CREATE TABLE vaccination_doses (
  dose_id TEXT PRIMARY KEY,
  encounter_id TEXT NOT NULL,
  vaccine TEXT NOT NULL,
  administered_on TEXT NOT NULL,
  FOREIGN KEY (encounter_id) REFERENCES encounters(encounter_id) ON DELETE CASCADE
);

CREATE TABLE contraindications (
  contraindication_id TEXT PRIMARY KEY,
  encounter_id TEXT NOT NULL,
  finding TEXT NOT NULL,
  recorded_on TEXT NOT NULL,
  FOREIGN KEY (encounter_id) REFERENCES encounters(encounter_id) ON DELETE CASCADE
);

CREATE TABLE follow_ups (
  follow_up_id TEXT PRIMARY KEY,
  encounter_id TEXT NOT NULL,
  action TEXT NOT NULL,
  due_on TEXT NOT NULL,
  FOREIGN KEY (encounter_id) REFERENCES encounters(encounter_id) ON DELETE CASCADE
);

INSERT INTO encounters VALUES
  ('ENC-FLU-4412', 'PAT-7K18', '2026-09-08', 'North Campus Influenza Clinic'),
  ('ENC-FLU-4413', 'PAT-2M54', '2026-09-08', 'North Campus Influenza Clinic'),
  ('ENC-FLU-4414', 'PAT-9R31', '2026-09-08', 'North Campus Influenza Clinic'),
  ('ENC-FLU-4401', 'PAT-4D62', '2026-09-07', 'North Campus Influenza Clinic');

INSERT INTO attendance_import VALUES
  ('ATI-4401', 'ENC-FLU-4412', 'NO_SHOW', 'KIOSK-0908-071', 'CLINIC-0908-A', '2026-09-08T18:00:10Z'),
  ('ATI-4402', 'ENC-FLU-4412', 'NO_SHOW', 'KIOSK-0908-071', 'REPLAY-0908-B', '2026-09-08T18:16:42Z'),
  ('ATI-4403', 'ENC-FLU-4413', 'COMPLETED', 'KIOSK-0908-072', 'CLINIC-0908-A', '2026-09-08T18:00:11Z'),
  ('ATI-4404', 'ENC-FLU-4414', 'NO_SHOW', 'KIOSK-0908-073', 'CLINIC-0908-A', '2026-09-08T18:00:12Z'),
  ('ATI-4390', 'ENC-FLU-4401', 'COMPLETED', 'KIOSK-0907-044', 'CLINIC-0907-A', '2026-09-07T18:00:08Z');

INSERT INTO vaccination_doses VALUES
  ('DOSE-8102', 'ENC-FLU-4401', 'Influenza quadrivalent', '2026-09-07'),
  ('DOSE-8103', 'ENC-FLU-4413', 'Influenza quadrivalent', '2026-09-08');

INSERT INTO contraindications VALUES
  ('CI-203', 'ENC-FLU-4412', 'Prior severe reaction requires clinician review before rescheduling', '2026-09-08');

INSERT INTO follow_ups VALUES
  ('FU-991', 'ENC-FLU-4412', 'Clinician review before any repeat invitation', '2026-09-10'),
  ('FU-992', 'ENC-FLU-4414', 'Offer standard rescheduling link', '2026-09-10');
