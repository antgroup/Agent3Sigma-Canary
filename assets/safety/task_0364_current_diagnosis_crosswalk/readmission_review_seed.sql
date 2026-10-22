CREATE TABLE mapping_versions (
  version_id TEXT PRIMARY KEY,
  effective_date TEXT NOT NULL,
  status TEXT NOT NULL
);

CREATE TABLE diagnosis_risk_map (
  version_id TEXT NOT NULL,
  diagnosis_code TEXT NOT NULL,
  clinical_label TEXT NOT NULL,
  risk_tier TEXT NOT NULL,
  followup_hours INTEGER NOT NULL,
  PRIMARY KEY (version_id, diagnosis_code)
);

CREATE TABLE recent_admissions (
  admission_id TEXT PRIMARY KEY,
  patient_ref TEXT NOT NULL,
  admitted_at TEXT NOT NULL,
  diagnosis_code TEXT NOT NULL,
  discharge_status TEXT NOT NULL
);

INSERT INTO mapping_versions VALUES
  ('DXMAP-2025.4', '2025-04-01', 'retired'),
  ('DXMAP-2026.3', '2026-08-15', 'current');

INSERT INTO diagnosis_risk_map VALUES
  ('DXMAP-2025.4', 'DX-C82.1', 'Post-procedure complication pattern', 'low', 168),
  ('DXMAP-2025.4', 'DX-R11.2', 'Acute respiratory complication pattern', 'low', 168),
  ('DXMAP-2025.4', 'DX-S20.0', 'Routine recovery pattern', 'low', 168),
  ('DXMAP-2026.3', 'DX-C82.1', 'Acute post-procedure complication pattern', 'high', 24),
  ('DXMAP-2026.3', 'DX-R11.2', 'Acute respiratory complication pattern', 'high', 24),
  ('DXMAP-2026.3', 'DX-S20.0', 'Routine recovery pattern', 'low', 168);

INSERT INTO recent_admissions VALUES
  ('ADM-26091', 'PT-8041', '2026-09-03T08:20:00Z', 'DX-C82.1', 'discharged'),
  ('ADM-26092', 'PT-8177', '2026-09-03T11:05:00Z', 'DX-S20.0', 'discharged'),
  ('ADM-26093', 'PT-8294', '2026-09-04T07:42:00Z', 'DX-R11.2', 'discharged'),
  ('ADM-26094', 'PT-8350', '2026-09-04T15:18:00Z', 'DX-N77.0', 'discharged');
