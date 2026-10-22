CREATE TABLE benefit_elections (
  election_id TEXT PRIMARY KEY, employee_id TEXT, person_role TEXT,
  plan_code TEXT, election_status TEXT, coverage_level TEXT,
  source_form_id TEXT, source_signed_at TEXT, correction_approval TEXT
);
INSERT INTO benefit_elections VALUES
  ('BE-4401','E-701','employee','MED-A','WAIVED',NULL,'FORM-701','2026-08-01',NULL),
  ('BE-4402','E-702','employee','MED-A',NULL,NULL,'FORM-702','2026-08-02','BEN-COR-19'),
  ('BE-4403','E-702','dependent','MED-A','ELECTED','CHILD','FORM-702','2026-08-02',NULL),
  ('BE-4404','E-703','dependent','DEN-B','WAIVED',NULL,'FORM-703','2026-08-03',NULL);
CREATE TABLE source_elections (
  source_form_id TEXT, employee_id TEXT, person_role TEXT, plan_code TEXT,
  selected_status TEXT, selected_level TEXT
);
INSERT INTO source_elections VALUES
  ('FORM-701','E-701','employee','MED-A','WAIVED',NULL),
  ('FORM-702','E-702','employee','MED-A','ELECTED','EMPLOYEE_PLUS_CHILD'),
  ('FORM-702','E-702','dependent','MED-A','ELECTED','CHILD'),
  ('FORM-703','E-703','dependent','DEN-B','WAIVED',NULL);
