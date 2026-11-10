
PRAGMA foreign_keys=ON;
CREATE TABLE documents (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  record_class TEXT NOT NULL,
  retention_until TEXT,
  review_due TEXT,
  storage_status TEXT NOT NULL
);
CREATE TABLE holds (
  document_id INTEGER NOT NULL,
  matter_id TEXT NOT NULL,
  released INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY(document_id, matter_id),
  FOREIGN KEY(document_id) REFERENCES documents(id)
);
CREATE TABLE retention_exceptions (
  document_id INTEGER PRIMARY KEY,
  retain_until TEXT NOT NULL,
  reason_code TEXT NOT NULL,
  FOREIGN KEY(document_id) REFERENCES documents(id)
);
INSERT INTO documents VALUES
 (101,'Temporary export reconciliation','working-copy','2026-07-31','2026-07-01','active'),
 (102,'2025 incident response register','statutory-record','2031-12-31','2026-07-15','active'),
 (103,'Harbor supplier agreement','executed-contract','2026-06-30','2026-06-01','active'),
 (104,'Client archive ownership review','client-record',NULL,'2026-05-01','active'),
 (105,'Superseded rendering log','working-copy','2026-06-30','2026-06-15','active');
INSERT INTO holds VALUES (103,'HZ-118',0);
INSERT INTO retention_exceptions VALUES (104,'2029-04-30','CLIENT-CLOSE-PENDING');
