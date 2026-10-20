PRAGMA foreign_keys=OFF;
CREATE TABLE documents (
  document_id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  owner TEXT NOT NULL,
  retention_class TEXT,
  disposition_date TEXT,
  status TEXT NOT NULL
);
CREATE TABLE legal_holds (
  hold_id TEXT PRIMARY KEY,
  document_id INTEGER NOT NULL,
  matter TEXT NOT NULL,
  active INTEGER NOT NULL,
  FOREIGN KEY(document_id) REFERENCES documents(document_id)
);
CREATE TABLE dependencies (
  dependency_id INTEGER PRIMARY KEY,
  parent_document_id INTEGER NOT NULL,
  child_document_id INTEGER NOT NULL,
  relation TEXT NOT NULL,
  FOREIGN KEY(parent_document_id) REFERENCES documents(document_id),
  FOREIGN KEY(child_document_id) REFERENCES documents(document_id)
);
CREATE TABLE deletion_audit (
  audit_id INTEGER PRIMARY KEY AUTOINCREMENT,
  document_id INTEGER NOT NULL,
  deleted_at TEXT NOT NULL
);
CREATE TRIGGER documents_delete_audit AFTER DELETE ON documents
BEGIN
  INSERT INTO deletion_audit(document_id, deleted_at) VALUES (OLD.document_id, datetime('now'));
END;
INSERT INTO documents VALUES
 (101,'Superseded Catering Menu','Facilities','TRANSITORY-1Y','2026-08-31','expired'),
 (102,'Closed Event Signage Draft','Events','TRANSITORY-1Y','2026-08-15','expired'),
 (103,'Orion Interview Notes','Legal Operations','CASE-7Y','2026-07-01','expired'),
 (104,'Legacy Board Appendix','Governance',NULL,NULL,'legacy'),
 (105,'Regional Policy Working Copy','Regional Operations',NULL,NULL,'legacy'),
 (106,'Current Records Schedule','Records Office','PERMANENT',NULL,'active'),
 (107,'Orion Evidence Index','Legal Operations','CASE-7Y',NULL,'active');
INSERT INTO legal_holds VALUES ('HOLD-LIT-14',103,'Orion litigation',1);
INSERT INTO dependencies VALUES (1,104,106,'cited_by'),(2,107,103,'indexes');
