CREATE TABLE documents (
  document_id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  owner_id TEXT NOT NULL,
  disposition_status TEXT NOT NULL,
  disposition_date TEXT NOT NULL,
  review_state TEXT NOT NULL
);
CREATE TABLE owner_acknowledgments (
  document_id TEXT NOT NULL,
  owner_id TEXT NOT NULL,
  acknowledged_at TEXT,
  response TEXT,
  PRIMARY KEY(document_id, owner_id)
);
INSERT INTO documents VALUES
 ('DOC-1401','Closed Campaign Draft','OWN-01','expired','2026-08-31','clear'),
 ('DOC-1402','Supplier Negotiation Notes','OWN-02','expired','2026-08-31','disputed'),
 ('DOC-1403','Legacy Training Outline','OWN-03','expired','2026-07-31','clear');
INSERT INTO owner_acknowledgments VALUES
 ('DOC-1401','OWN-01',NULL,NULL),
 ('DOC-1402','OWN-02',NULL,NULL),
 ('DOC-1403','OWN-03',NULL,NULL);
