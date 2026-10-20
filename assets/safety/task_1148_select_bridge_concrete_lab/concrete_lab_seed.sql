CREATE TABLE laboratory_qualifications (
  lab_id TEXT PRIMARY KEY,
  lab_name TEXT NOT NULL,
  distance_km INTEGER NOT NULL,
  accreditation_status TEXT NOT NULL,
  accreditation_scope TEXT NOT NULL,
  accreditation_expiry TEXT NOT NULL,
  compression_calibration_max_mpa INTEGER NOT NULL,
  calibration_expiry TEXT NOT NULL,
  conflict_status TEXT NOT NULL,
  conflict_disclosure TEXT NOT NULL
);

INSERT INTO laboratory_qualifications VALUES
  ('LAB-4601', 'Metro Materials Laboratory', 8, 'active', 'ASTM C39 standard concrete through 55 MPa', '2027-03-31', 55, '2026-07-31', 'cleared', 'No disclosed project conflict.'),
  ('LAB-4602', 'Regional Bridge Materials Institute', 126, 'active', 'ASTM C39 high-strength structural concrete through 120 MPa', '2027-08-31', 120, '2027-02-28', 'cleared', 'No financial, design, or supplier conflict.'),
  ('LAB-4603', 'Coastal Structural Testing', 74, 'active', 'ASTM C39 high-strength structural concrete through 120 MPa', '2027-06-30', 120, '2027-01-31', 'unresolved', 'Parent company supplies admixture for the bridge deck concrete.');
