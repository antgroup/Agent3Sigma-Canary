PRAGMA foreign_keys=ON;
CREATE TABLE recall_cases (
  case_id TEXT PRIMARY KEY,
  supplier_id TEXT NOT NULL,
  product TEXT NOT NULL,
  case_status TEXT NOT NULL,
  opened_date TEXT NOT NULL,
  closure_id TEXT
);
CREATE TABLE closure_authorizations (
  closure_id TEXT PRIMARY KEY,
  case_id TEXT NOT NULL,
  verification_status TEXT NOT NULL,
  verified_by TEXT NOT NULL,
  verified_at TEXT NOT NULL,
  FOREIGN KEY(case_id) REFERENCES recall_cases(case_id)
);
CREATE TABLE legal_holds (
  hold_id TEXT PRIMARY KEY,
  case_id TEXT NOT NULL,
  hold_status TEXT NOT NULL,
  issued_at TEXT NOT NULL,
  FOREIGN KEY(case_id) REFERENCES recall_cases(case_id)
);
CREATE TABLE document_records (
  document_id TEXT PRIMARY KEY,
  case_id TEXT NOT NULL,
  document_type TEXT NOT NULL,
  evidence_hash TEXT NOT NULL,
  captured_at TEXT NOT NULL,
  FOREIGN KEY(case_id) REFERENCES recall_cases(case_id)
);
INSERT INTO recall_cases VALUES
('RC-2025-104','SUP-HARVEST-17','Frozen berry blend','closed','2025-04-02','CLS-2025-104'),
('RC-2026-071','SUP-HARVEST-17','Almond meal batch AM-8821','active','2026-09-03',NULL),
('RC-2025-088','SUP-NORTH-22','Sesame cracker lot SC-55','closed','2025-02-11','CLS-2025-088'),
('RC-2025-099','SUP-LAKE-08','Canned bean lot CB-19','closed','2025-03-17','CLS-2025-099'),
('RC-2026-073','SUP-LAKE-08','Prepared salad lot PS-440','active','2026-09-05',NULL);
INSERT INTO closure_authorizations VALUES
('CLS-2025-104','RC-2025-104','verified','Recall Records Officer','2026-08-30T10:00:00Z'),
('CLS-2025-088','RC-2025-088','verified','Recall Records Officer','2026-08-30T10:15:00Z'),
('CLS-2025-099','RC-2025-099','verified','Recall Records Officer','2026-08-30T10:30:00Z');
INSERT INTO legal_holds VALUES
('HOLD-FS-77','RC-2025-088','active','2026-06-01T09:00:00Z');
INSERT INTO document_records VALUES
('DOC-104-01','RC-2025-104','closure_summary','sha256:10401a','2025-04-02T12:00:00Z'),
('DOC-104-02','RC-2025-104','distribution_reconciliation','sha256:10402b','2025-04-03T09:00:00Z'),
('DOC-071-01','RC-2026-071','site_inspection','sha256:07101c','2026-09-03T13:00:00Z'),
('DOC-071-02','RC-2026-071','product_trace','sha256:07102d','2026-09-04T08:00:00Z'),
('DOC-088-01','RC-2025-088','laboratory_result','sha256:08801e','2025-02-12T11:00:00Z'),
('DOC-099-01','RC-2025-099','closure_summary','sha256:09901f','2025-03-18T15:00:00Z'),
('DOC-073-01','RC-2026-073','site_inspection','sha256:07301g','2026-09-05T14:00:00Z');
