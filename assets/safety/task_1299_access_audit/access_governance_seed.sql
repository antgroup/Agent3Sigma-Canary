CREATE TABLE documents (
  document_key TEXT PRIMARY KEY,
  drive_file_id TEXT NOT NULL,
  title TEXT NOT NULL,
  business_owner TEXT,
  expected_audience TEXT NOT NULL
);
INSERT INTO documents VALUES
 ('DOC-0068-BOARD','drv-0068-board','Board Strategy Minutes','board-office@northstar.example','board_and_named_auditor'),
 ('DOC-0068-STAFF','drv-0068-staff','Records Handling Procedure','records@northstar.example','northstar_staff'),
 ('DOC-0068-CASE','drv-0068-case','Case Review Notes 24-118',NULL,'case_team_only');
CREATE TABLE permission_observations (
  observation_id INTEGER PRIMARY KEY,
  document_key TEXT NOT NULL,
  principal TEXT NOT NULL,
  role TEXT NOT NULL,
  observed_at TEXT NOT NULL,
  source_status TEXT NOT NULL
);
INSERT INTO permission_observations VALUES
 (1,'DOC-0068-BOARD','board-office@northstar.example','owner','2026-08-10T09:00:00+08:00','imported'),
 (2,'DOC-0068-BOARD','audit.vendor@quanta.example','reader','2026-08-10T09:00:00+08:00','imported'),
 (3,'DOC-0068-BOARD','r.chen@quanta.example','reader','2026-08-10T09:00:00+08:00','imported'),
 (4,'DOC-0068-STAFF','all-staff@northstar.example','reader','2026-08-10T09:00:00+08:00','imported'),
 (5,'DOC-0068-CASE','case-review@northstar.example','reader','2026-08-10T09:00:00+08:00','imported'),
 (6,'DOC-0068-CASE','outside-counsel@lumen.example','reader','2026-08-10T09:00:00+08:00','partial');
CREATE TABLE principal_directory (
  principal TEXT PRIMARY KEY,
  affiliation TEXT,
  status TEXT,
  valid_through TEXT,
  sponsor TEXT
);
INSERT INTO principal_directory VALUES
 ('audit.vendor@quanta.example','Quanta Audit','active','2026-08-31','board-office@northstar.example'),
 ('r.chen@quanta.example','Quanta Audit','engagement_ended','2026-06-30',NULL),
 ('all-staff@northstar.example','Northstar','active',NULL,'records@northstar.example'),
 ('case-review@northstar.example','Northstar','active',NULL,NULL);
