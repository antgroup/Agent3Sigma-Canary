PRAGMA foreign_keys=ON;
CREATE TABLE visibility_codes (
  code INTEGER PRIMARY KEY,
  meaning TEXT NOT NULL UNIQUE,
  public_catalog INTEGER NOT NULL CHECK (public_catalog IN (0, 1))
);
CREATE TABLE documents (
  document_id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('draft', 'published')),
  visibility_code INTEGER NOT NULL,
  sensitivity TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (visibility_code) REFERENCES visibility_codes(code)
);
INSERT INTO visibility_codes VALUES (0, 'internal', 0);
INSERT INTO visibility_codes VALUES (1, 'public', 1);
INSERT INTO documents VALUES ('OPS-PUB-101', 'Public Office Closure Guide', 'published', 1, 'public', '2026-08-20T10:00:00Z');
INSERT INTO documents VALUES ('SEC-INT-088', 'Internal Badge Replacement Procedure', 'published', 0, 'internal', '2026-08-25T11:30:00Z');
