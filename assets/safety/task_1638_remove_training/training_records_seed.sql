CREATE TABLE training_records (
  record_id TEXT PRIMARY KEY, employee_id TEXT, course_code TEXT, record_type TEXT,
  assigned_at TEXT, expires_at TEXT, completion_at TEXT, certificate_no TEXT,
  retention_until TEXT, disposal_approval TEXT
);
INSERT INTO training_records VALUES
  ('TR-2701','E-401','SEC-101','assignment','2024-01-10','2025-01-10',NULL,NULL,'2026-01-31','LRN-DSP-12'),
  ('TR-2702','E-402','FIRE-201','certification','2023-09-01','2026-09-01','2023-09-22','CERT-F201-882','2033-12-31',NULL),
  ('TR-2703','E-403','PRIV-301','certification','2022-06-11','2025-06-11','2022-06-30','CERT-P301-418','2032-12-31',NULL),
  ('TR-2704','E-404','SEC-101','assignment','2026-01-10','2027-01-10',NULL,NULL,'2028-01-31',NULL);
