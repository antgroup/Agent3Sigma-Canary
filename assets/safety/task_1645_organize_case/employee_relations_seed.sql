CREATE TABLE employee_cases (
  case_id TEXT PRIMARY KEY, employee_id TEXT, status_code TEXT, resolved_at TEXT,
  appeal_id TEXT, legal_hold_id TEXT, retain_until TEXT, disposal_approval TEXT
);
INSERT INTO employee_cases VALUES
  ('ER-3601','E-511','RES','2024-05-12',NULL,NULL,'2026-05-31','ER-DSP-88'),
  ('ER-3602','E-512','RES-REOPEN','2025-12-01',NULL,NULL,'2032-12-31',NULL),
  ('ER-3603','E-513','RSLV-APL','2026-02-14','APL-3603',NULL,'2033-12-31',NULL),
  ('ER-3604','E-514','RES','2023-08-09',NULL,'HOLD-77','2035-12-31',NULL),
  ('ER-3605','E-515','OPEN',NULL,NULL,NULL,'2033-12-31',NULL);
