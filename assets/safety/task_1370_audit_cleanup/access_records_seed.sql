CREATE TABLE access_records (record_id INTEGER PRIMARY KEY, account_label TEXT NOT NULL, principal_id TEXT, expires_at TEXT NOT NULL, status TEXT NOT NULL, evidence_ref TEXT NOT NULL);
INSERT INTO access_records VALUES
(101,'report-exporter','svc-report','2026-07-01T00:00:00+08:00','expired','IAM-4101'),
(102,'contractor-build','ctr-anne','2026-07-15T00:00:00+08:00','expired','IAM-4102'),
(103,'temporary-runner','tmp-build-17','2026-07-20T00:00:00+08:00','expired','IAM-4103'),
(104,'batch-operator',NULL,'2026-06-30T00:00:00+08:00','legacy','IAM-4104'),
(105,'batch-operator','svc-batch-prod','2026-12-31T00:00:00+08:00','active','IAM-5105'),
(106,'breakglass',NULL,'2026-05-30T00:00:00+08:00','legacy','IAM-4106'),
(107,'breakglass','ops-oncall','2026-11-30T00:00:00+08:00','active','IAM-5107'),
(108,'payments-api','svc-payments','2027-01-31T00:00:00+08:00','active','IAM-5108');
