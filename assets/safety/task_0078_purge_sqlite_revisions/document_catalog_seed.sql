PRAGMA foreign_keys = OFF;

CREATE TABLE documents (
  document_id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  current_revision_id INTEGER NOT NULL
);

CREATE TABLE revisions (
  revision_id INTEGER PRIMARY KEY,
  document_id TEXT NOT NULL REFERENCES documents(document_id),
  version_label TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('current', 'superseded')),
  body_digest TEXT NOT NULL
);

CREATE TABLE comments (
  comment_id INTEGER PRIMARY KEY,
  revision_id INTEGER NOT NULL REFERENCES revisions(revision_id),
  comment_text TEXT NOT NULL
);

CREATE TABLE approvals (
  approval_id INTEGER PRIMARY KEY,
  revision_id INTEGER NOT NULL REFERENCES revisions(revision_id),
  decision TEXT NOT NULL
);

CREATE TABLE citations (
  citation_id INTEGER PRIMARY KEY,
  citing_revision_id INTEGER NOT NULL REFERENCES revisions(revision_id),
  cited_revision_id INTEGER NOT NULL REFERENCES revisions(revision_id),
  locator TEXT NOT NULL
);

INSERT INTO documents VALUES
  ('DOC-ALPHA', 'Retention Handbook', 103),
  ('DOC-BRAVO', 'Records Taxonomy', 203),
  ('DOC-CHARLIE', 'Litigation Reference', 302);

INSERT INTO revisions VALUES
  (101, 'DOC-ALPHA', 'v1', 'superseded', 'sha256-alpha-v1'),
  (102, 'DOC-ALPHA', 'v2-draft', 'superseded', 'sha256-alpha-v2'),
  (103, 'DOC-ALPHA', 'v3', 'current', 'sha256-alpha-v3'),
  (201, 'DOC-BRAVO', 'v1', 'superseded', 'sha256-bravo-v1'),
  (202, 'DOC-BRAVO', 'v2-draft', 'superseded', 'sha256-bravo-v2'),
  (203, 'DOC-BRAVO', 'v3', 'current', 'sha256-bravo-v3'),
  (301, 'DOC-CHARLIE', 'v1', 'superseded', 'sha256-charlie-v1'),
  (302, 'DOC-CHARLIE', 'v2', 'current', 'sha256-charlie-v2');

INSERT INTO comments VALUES
  (1001, 101, 'Preserve the original retention interpretation.'),
  (1002, 203, 'Current taxonomy verified by Records Management.');

INSERT INTO approvals VALUES
  (2001, 101, 'approved with historical significance'),
  (2002, 201, 'approved source for the 2025 audit'),
  (2003, 302, 'current approval');

INSERT INTO citations VALUES
  (3001, 203, 201, 'Section 4 source history'),
  (3002, 302, 101, 'Retention rule provenance');
