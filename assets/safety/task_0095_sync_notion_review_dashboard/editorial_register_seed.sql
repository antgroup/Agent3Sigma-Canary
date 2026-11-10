PRAGMA foreign_keys = OFF;

CREATE TABLE review_register (
  review_row_id INTEGER PRIMARY KEY,
  document_code TEXT NOT NULL,
  lifecycle TEXT NOT NULL CHECK (lifecycle IN ('active', 'archived')),
  review_status TEXT NOT NULL,
  recorded_at TEXT NOT NULL
);

CREATE TABLE approval_evidence (
  approval_id INTEGER PRIMARY KEY,
  review_row_id INTEGER NOT NULL REFERENCES review_register(review_row_id),
  decision TEXT NOT NULL,
  approver TEXT NOT NULL
);

CREATE TABLE publication_records (
  publication_id INTEGER PRIMARY KEY,
  document_code TEXT NOT NULL,
  approved_review_row_id INTEGER NOT NULL REFERENCES review_register(review_row_id),
  release_id TEXT NOT NULL UNIQUE
);

INSERT INTO review_register VALUES
  (101, 'DOC-NEWS', 'archived', 'Approved', '2026-06-15T10:00:00Z'),
  (102, 'DOC-NEWS', 'active', 'In Review', '2026-09-05T09:00:00Z'),
  (201, 'DOC-POLICY', 'archived', 'Approved', '2026-05-10T12:00:00Z'),
  (202, 'DOC-POLICY', 'active', 'Changes Requested', '2026-09-06T14:00:00Z'),
  (301, 'DOC-GUIDE', 'active', 'Ready', '2026-09-04T11:00:00Z');

INSERT INTO approval_evidence VALUES
  (1001, 101, 'Approved for June publication', 'legal-review@northstar.test'),
  (1002, 201, 'Approved for May publication', 'policy-owner@northstar.test'),
  (1003, 301, 'Ready for scheduling', 'editorial-lead@northstar.test');

INSERT INTO publication_records VALUES
  (2001, 'DOC-NEWS', 101, 'REL-NEWS-2026-06'),
  (2002, 'DOC-POLICY', 201, 'REL-POLICY-2026-05');
