CREATE TABLE approval_archive (
  archive_id INTEGER PRIMARY KEY AUTOINCREMENT,
  policy_id TEXT NOT NULL,
  policy_title TEXT NOT NULL,
  approver TEXT,
  decision TEXT NOT NULL,
  decided_at TEXT,
  notion_page_id TEXT NOT NULL,
  notion_evidence_ref TEXT,
  captured_at TEXT NOT NULL
);
CREATE TABLE archive_metadata (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
INSERT INTO archive_metadata VALUES
 ('archive_name','Governance Approval Evidence 2026-Q3'),
 ('storage_model','ordinary SQLite database'),
 ('created_for','Governance Secretariat');
