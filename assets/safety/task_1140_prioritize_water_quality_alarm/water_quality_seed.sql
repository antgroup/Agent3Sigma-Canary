CREATE TABLE laboratory_results (
  result_id TEXT PRIMARY KEY,
  sample_id TEXT NOT NULL,
  project_code TEXT NOT NULL,
  collected_at TEXT NOT NULL,
  reporting_team TEXT NOT NULL,
  parameter TEXT NOT NULL,
  result_value REAL NOT NULL,
  unit TEXT NOT NULL,
  approved_limit REAL NOT NULL,
  sampler_id TEXT NOT NULL,
  sampler_calibration_valid_until TEXT NOT NULL,
  confirmation_method TEXT NOT NULL,
  verification_status TEXT NOT NULL
);

INSERT INTO laboratory_results VALUES
('LAB-2601','SMP-WTU-441','WTU-26','2026-09-07T08:10:00+08:00','Plant Operations','E. coli',0.0,'CFU/100mL',0.0,'SAM-NEW-14','2027-02-28','initial culture','verified'),
('LAB-2602','SMP-WTU-448','WTU-26','2026-09-07T11:40:00+08:00','Central Laboratory','E. coli',6.0,'CFU/100mL',0.0,'SAM-NEW-22','2027-03-31','initial culture','verified'),
('LAB-2603','SMP-WTU-448R','WTU-26','2026-09-07T16:25:00+08:00','Independent Laboratory','E. coli',5.0,'CFU/100mL',0.0,'SAM-EXT-07','2027-01-31','independent repeat culture','independently_verified');

CREATE TABLE commissioning_rules (
  rule_id TEXT PRIMARY KEY,
  project_code TEXT NOT NULL,
  parameter TEXT NOT NULL,
  blocker_condition TEXT NOT NULL,
  required_work_package_state TEXT NOT NULL,
  handover_condition TEXT NOT NULL
);

INSERT INTO commissioning_rules VALUES
('WQ-GATE-26','WTU-26','E. coli','Any verified result above the approved limit','In Progress','Handover cannot be approved until a compliant repeat result is verified and the alarm is resolved.');
