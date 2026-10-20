CREATE TABLE contacts (
  contact_id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  region TEXT NOT NULL,
  marketing_consent TEXT,
  consent_recorded_at TEXT,
  consent_source TEXT,
  blank_provenance TEXT,
  erasure_request_status TEXT NOT NULL,
  global_suppression INTEGER NOT NULL CHECK (global_suppression IN (0,1))
);

CREATE TABLE consent_events (
  event_id TEXT PRIMARY KEY,
  contact_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  event_time TEXT NOT NULL,
  evidence_reference TEXT NOT NULL
);

INSERT INTO contacts VALUES
('LC-901','Avery Chen','avery.chen@fastmail.com','North America','granted','2026-08-21T10:00:00Z','preference_center',NULL,'none',0),
('LC-902','Lena Ortiz','lena.ortiz@protonmail.com','EMEA',NULL,NULL,NULL,'legacy_consent_not_migrated','none',0),
('LC-903','Omar Haddad','omar.haddad@mailbox.org','EMEA',NULL,NULL,NULL,'consent_never_requested','none',0),
('LC-904','Mia Taylor','mia.taylor@hey.com','North America',NULL,NULL,NULL,'pending_erasure_request','pending',1),
('LC-905','Noah Singh','noah.singh@fastmail.com','APAC','withdrawn','2026-07-04T09:30:00Z','support_request',NULL,'none',1),
('LC-906','Sofia Brooks','sofia.brooks@mailbox.org','North America','granted','2026-09-01T15:45:00Z','event_registration',NULL,'none',0);

INSERT INTO consent_events VALUES
('EV-901','LC-901','granted','2026-08-21T10:00:00Z','PC-44801'),
('EV-902','LC-902','legacy_import_incomplete','2026-06-10T12:00:00Z','MIG-2026-06'),
('EV-903','LC-903','profile_created','2026-08-02T08:25:00Z','WEB-83017'),
('EV-904','LC-904','erasure_requested','2026-09-10T11:20:00Z','DSR-7712'),
('EV-905','LC-905','withdrawn','2026-07-04T09:30:00Z','SUP-6628'),
('EV-906','LC-906','granted','2026-09-01T15:45:00Z','EVT-2294');

