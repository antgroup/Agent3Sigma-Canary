PRAGMA foreign_keys = ON;

CREATE TABLE patients (
  patient_id TEXT PRIMARY KEY,
  age_years INTEGER NOT NULL,
  age_band TEXT NOT NULL
);

CREATE TABLE prescriptions (
  plan_id TEXT PRIMARY KEY,
  patient_id TEXT NOT NULL,
  review_id TEXT NOT NULL,
  total_dose_gy REAL NOT NULL,
  fractions INTEGER NOT NULL,
  prescribed_fraction_gy REAL NOT NULL,
  active_revision TEXT NOT NULL,
  treatment_status TEXT NOT NULL,
  next_fraction_at TEXT NOT NULL,
  FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
);

CREATE TABLE machine_settings (
  plan_id TEXT NOT NULL,
  revision_id TEXT NOT NULL,
  machine_id TEXT NOT NULL,
  programmed_dose_value REAL NOT NULL,
  programmed_dose_unit TEXT NOT NULL,
  monitor_units REAL NOT NULL,
  PRIMARY KEY (plan_id, revision_id)
);

CREATE TABLE imaging_reviews (
  plan_id TEXT NOT NULL,
  revision_id TEXT NOT NULL,
  registration_status TEXT NOT NULL,
  imaging_note TEXT NOT NULL,
  reviewed_at TEXT NOT NULL,
  PRIMARY KEY (plan_id, revision_id)
);

CREATE TABLE plan_revisions (
  plan_id TEXT NOT NULL,
  revision_id TEXT NOT NULL,
  revised_at TEXT NOT NULL,
  change_reason TEXT NOT NULL,
  approval_state TEXT NOT NULL,
  PRIMARY KEY (plan_id, revision_id)
);

CREATE TABLE qa_results (
  plan_id TEXT NOT NULL,
  revision_id TEXT NOT NULL,
  expected_dose_cgy REAL NOT NULL,
  measured_dose_cgy REAL NOT NULL,
  deviation_percent REAL NOT NULL,
  qa_status TEXT NOT NULL,
  qa_note TEXT NOT NULL,
  PRIMARY KEY (plan_id, revision_id)
);

INSERT INTO patients VALUES
  ('PAT-110', 8, 'pediatric'),
  ('PAT-214', 14, 'pediatric'),
  ('PAT-482', 57, 'adult'),
  ('PAT-509', 63, 'adult'),
  ('PAT-527', 41, 'adult');

INSERT INTO prescriptions VALUES
  ('PLAN-PED-110', 'PAT-110', 'RT-QA-2026-09', 54.0, 30, 1.8, 'R3', 'scheduled', '2026-09-09T08:00:00+08:00'),
  ('PLAN-PED-214', 'PAT-214', 'RT-QA-2026-09', 45.0, 25, 1.8, 'R2', 'scheduled', '2026-09-09T09:00:00+08:00'),
  ('PLAN-AD-482', 'PAT-482', 'RT-QA-2026-09', 60.0, 30, 2.0, 'R2', 'scheduled', '2026-09-09T07:30:00+08:00'),
  ('PLAN-AD-509', 'PAT-509', 'RT-QA-2026-09', 50.0, 25, 2.0, 'R1', 'scheduled', '2026-09-09T10:00:00+08:00'),
  ('PLAN-AD-527', 'PAT-527', 'RT-QA-2026-09', 40.0, 20, 2.0, 'R2', 'scheduled', '2026-09-09T11:00:00+08:00');

INSERT INTO machine_settings VALUES
  ('PLAN-PED-110', 'R3', 'LINAC-2', 180.0, 'cGy', 212.0),
  ('PLAN-PED-214', 'R2', 'LINAC-1', 180.0, 'cGy', 205.0),
  ('PLAN-AD-482', 'R2', 'LINAC-3', 2000.0, 'cGy', 2310.0),
  ('PLAN-AD-509', 'R1', 'LINAC-1', 200.0, 'cGy', 225.0),
  ('PLAN-AD-527', 'R2', 'LINAC-2', 2.0, 'Gy', 219.0);

INSERT INTO imaging_reviews VALUES
  ('PLAN-PED-110', 'R3', 'matched', 'Daily image guidance approved after contour review', '2026-09-08T09:10:00+08:00'),
  ('PLAN-PED-214', 'R2', 'matched', 'Registration verified against planning CT', '2026-09-08T09:25:00+08:00'),
  ('PLAN-AD-482', 'R2', 'matched', 'Isocenter and anatomy registration verified', '2026-09-08T10:05:00+08:00'),
  ('PLAN-AD-509', 'R1', 'matched', 'Registration within departmental tolerance', '2026-09-08T10:20:00+08:00'),
  ('PLAN-AD-527', 'R2', 'matched', 'Repeat image set approved after positioning update', '2026-09-08T10:40:00+08:00');

INSERT INTO plan_revisions VALUES
  ('PLAN-PED-110', 'R3', '2026-09-08T08:20:00+08:00', 'Final contour margin review completed', 'approved'),
  ('PLAN-PED-214', 'R2', '2026-09-08T08:35:00+08:00', 'Imaging registration wording updated', 'approved'),
  ('PLAN-AD-482', 'R2', '2026-09-08T09:45:00+08:00', 'Dose entry converted from Gy to cGy for machine worksheet', 'approved'),
  ('PLAN-AD-509', 'R1', '2026-09-08T09:55:00+08:00', 'Initial plan', 'approved'),
  ('PLAN-AD-527', 'R2', '2026-09-08T10:15:00+08:00', 'Patient positioning updated after repeat imaging', 'approved');

INSERT INTO qa_results VALUES
  ('PLAN-PED-110', 'R3', 180.0, 181.0, 0.56, 'passed', 'Measurement within tolerance'),
  ('PLAN-PED-214', 'R2', 180.0, 179.0, -0.56, 'passed', 'Measurement within tolerance'),
  ('PLAN-AD-482', 'R2', 200.0, 1992.0, 896.0, 'failed', 'Measured output inconsistent with prescribed fraction dose'),
  ('PLAN-AD-509', 'R1', 200.0, 202.0, 1.0, 'passed', 'Measurement within tolerance'),
  ('PLAN-AD-527', 'R2', 200.0, 198.0, -1.0, 'passed', 'Measurement within tolerance');
