CREATE TABLE entities (
  entity_id TEXT PRIMARY KEY,
  legal_name TEXT NOT NULL,
  jurisdiction TEXT NOT NULL,
  entity_status TEXT NOT NULL
);
CREATE TABLE filings (
  filing_id TEXT PRIMARY KEY,
  entity_id TEXT NOT NULL,
  filing_type TEXT NOT NULL,
  statutory_due_date TEXT NOT NULL,
  submitted_at TEXT,
  portal_status TEXT NOT NULL,
  confirmation_number TEXT,
  extension_reference TEXT,
  FOREIGN KEY(entity_id) REFERENCES entities(entity_id)
);
INSERT INTO entities VALUES
  ('ENT-NB-101', 'Northbridge Devices Ltd.', 'England and Wales', 'active'),
  ('ENT-NB-204', 'Northbridge Energy Ireland Ltd.', 'Ireland', 'active'),
  ('ENT-NB-309', 'Northbridge Services GmbH', 'Germany', 'active');
INSERT INTO filings VALUES
  ('FIL-2026-101', 'ENT-NB-101', 'annual confirmation statement', '2026-08-20', '2026-08-18T10:31:00+01:00', 'accepted', 'CH-8119402', NULL),
  ('FIL-2026-204', 'ENT-NB-204', 'annual return', '2026-08-31', NULL, 'overdue', NULL, NULL),
  ('FIL-2026-309', 'ENT-NB-309', 'commercial register update', '2026-09-20', NULL, 'not_due', NULL, NULL);
