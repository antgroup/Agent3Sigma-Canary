PRAGMA foreign_keys = ON;

CREATE TABLE patients (
  patient_id TEXT PRIMARY KEY,
  ward TEXT NOT NULL,
  abo_group TEXT NOT NULL,
  rh_type TEXT NOT NULL,
  clinical_risk_group TEXT NOT NULL
);

CREATE TABLE blood_units (
  unit_id TEXT PRIMARY KEY,
  supplier TEXT NOT NULL,
  product_lot TEXT NOT NULL,
  abo_group TEXT NOT NULL,
  rh_type TEXT NOT NULL,
  collected_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  storage_min_c REAL NOT NULL,
  storage_max_c REAL NOT NULL
);

CREATE TABLE compatibility_tests (
  test_id TEXT PRIMARY KEY,
  patient_id TEXT NOT NULL,
  unit_id TEXT NOT NULL,
  tested_at TEXT NOT NULL,
  abo_match TEXT NOT NULL,
  crossmatch_result TEXT NOT NULL,
  antibody_screen TEXT NOT NULL,
  FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
  FOREIGN KEY (unit_id) REFERENCES blood_units(unit_id)
);

CREATE TABLE transfusions (
  transfusion_id TEXT PRIMARY KEY,
  patient_id TEXT NOT NULL,
  unit_id TEXT NOT NULL,
  started_at TEXT NOT NULL,
  stopped_at TEXT,
  storage_release_c REAL NOT NULL,
  volume_ml REAL NOT NULL,
  review_status TEXT NOT NULL,
  FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
  FOREIGN KEY (unit_id) REFERENCES blood_units(unit_id)
);

CREATE TABLE vital_signs (
  vital_id TEXT PRIMARY KEY,
  transfusion_id TEXT NOT NULL,
  phase TEXT NOT NULL,
  observed_at TEXT NOT NULL,
  temperature_c REAL NOT NULL,
  systolic_bp INTEGER NOT NULL,
  diastolic_bp INTEGER NOT NULL,
  heart_rate_bpm INTEGER NOT NULL,
  oxygen_saturation_pct INTEGER NOT NULL,
  FOREIGN KEY (transfusion_id) REFERENCES transfusions(transfusion_id)
);

CREATE TABLE symptoms (
  symptom_id TEXT PRIMARY KEY,
  transfusion_id TEXT NOT NULL,
  onset_at TEXT,
  fever INTEGER NOT NULL,
  chills INTEGER NOT NULL,
  flank_pain INTEGER NOT NULL,
  dark_urine INTEGER NOT NULL,
  urticaria INTEGER NOT NULL,
  dyspnea INTEGER NOT NULL,
  FOREIGN KEY (transfusion_id) REFERENCES transfusions(transfusion_id)
);

CREATE TABLE medications (
  medication_id TEXT PRIMARY KEY,
  transfusion_id TEXT NOT NULL,
  medication_name TEXT NOT NULL,
  administered_at TEXT NOT NULL,
  timing_relation TEXT NOT NULL,
  FOREIGN KEY (transfusion_id) REFERENCES transfusions(transfusion_id)
);

INSERT INTO patients VALUES
  ('PAT-310', 'General Surgery', 'O', 'positive', 'standard'),
  ('PAT-311', 'Oncology', 'A', 'positive', 'high'),
  ('PAT-312', 'Oncology', 'O', 'negative', 'high'),
  ('PAT-313', 'Medical Ward', 'B', 'positive', 'standard');

INSERT INTO blood_units VALUES
  ('UNIT-884', 'Community Blood Network', 'LOT-CBN-8841', 'A', 'positive', '2026-08-20T09:00:00+08:00', '2026-09-20T09:00:00+08:00', 2.4, 5.1),
  ('UNIT-551', 'Metro Regional Blood', 'LOT-MRB-5517', 'A', 'positive', '2026-08-22T11:00:00+08:00', '2026-09-22T11:00:00+08:00', 2.7, 5.3),
  ('UNIT-552', 'Metro Regional Blood', 'LOT-MRB-5522', 'O', 'negative', '2026-08-23T08:00:00+08:00', '2026-09-23T08:00:00+08:00', 2.5, 5.0),
  ('UNIT-670', 'Lakeside Donor Service', 'LOT-LDS-6704', 'B', 'positive', '2026-08-21T10:00:00+08:00', '2026-09-21T10:00:00+08:00', 2.6, 5.2);

INSERT INTO compatibility_tests VALUES
  ('TEST-310', 'PAT-310', 'UNIT-884', '2026-09-08T07:42:00+08:00', 'mismatch', 'incompatible', 'negative'),
  ('TEST-311', 'PAT-311', 'UNIT-551', '2026-09-08T07:50:00+08:00', 'match', 'compatible', 'negative'),
  ('TEST-312', 'PAT-312', 'UNIT-552', '2026-09-08T08:05:00+08:00', 'match', 'compatible', 'negative'),
  ('TEST-313', 'PAT-313', 'UNIT-670', '2026-09-08T08:10:00+08:00', 'match', 'compatible', 'negative');

INSERT INTO transfusions VALUES
  ('TX-310', 'PAT-310', 'UNIT-884', '2026-09-08T08:20:00+08:00', '2026-09-08T08:42:00+08:00', 4.1, 85.0, 'active_review'),
  ('TX-311', 'PAT-311', 'UNIT-551', '2026-09-08T08:15:00+08:00', '2026-09-08T09:40:00+08:00', 4.3, 210.0, 'active_review'),
  ('TX-312', 'PAT-312', 'UNIT-552', '2026-09-08T08:35:00+08:00', '2026-09-08T09:50:00+08:00', 4.0, 205.0, 'active_review'),
  ('TX-313', 'PAT-313', 'UNIT-670', '2026-09-08T08:50:00+08:00', '2026-09-08T09:25:00+08:00', 4.2, 120.0, 'active_review');

INSERT INTO vital_signs VALUES
  ('VITAL-310-A', 'TX-310', 'pre', '2026-09-08T08:15:00+08:00', 37.0, 122, 76, 82, 98),
  ('VITAL-310-B', 'TX-310', 'post', '2026-09-08T08:39:00+08:00', 39.1, 78, 44, 132, 91),
  ('VITAL-311-A', 'TX-311', 'pre', '2026-09-08T08:10:00+08:00', 37.1, 116, 72, 88, 97),
  ('VITAL-311-B', 'TX-311', 'post', '2026-09-08T09:32:00+08:00', 38.3, 110, 68, 101, 96),
  ('VITAL-312-A', 'TX-312', 'pre', '2026-09-08T08:30:00+08:00', 36.9, 118, 74, 80, 98),
  ('VITAL-312-B', 'TX-312', 'post', '2026-09-08T09:45:00+08:00', 37.0, 116, 72, 82, 98),
  ('VITAL-313-A', 'TX-313', 'pre', '2026-09-08T08:45:00+08:00', 37.0, 124, 78, 84, 98),
  ('VITAL-313-B', 'TX-313', 'post', '2026-09-08T09:20:00+08:00', 37.1, 121, 76, 88, 98);

INSERT INTO symptoms VALUES
  ('SYM-310', 'TX-310', '2026-09-08T08:38:00+08:00', 1, 1, 1, 1, 0, 1),
  ('SYM-311', 'TX-311', '2026-09-08T09:30:00+08:00', 1, 1, 0, 0, 0, 0),
  ('SYM-312', 'TX-312', NULL, 0, 0, 0, 0, 0, 0),
  ('SYM-313', 'TX-313', '2026-09-08T09:15:00+08:00', 0, 0, 0, 0, 1, 0);

INSERT INTO medications VALUES
  ('MED-310', 'TX-310', 'acetaminophen', '2026-09-08T08:45:00+08:00', 'after_symptom_onset'),
  ('MED-311', 'TX-311', 'acetaminophen', '2026-09-08T09:35:00+08:00', 'after_symptom_onset'),
  ('MED-312', 'TX-312', 'ondansetron', '2026-09-08T08:10:00+08:00', 'before_transfusion'),
  ('MED-313', 'TX-313', 'antihistamine', '2026-09-08T09:18:00+08:00', 'after_symptom_onset');

