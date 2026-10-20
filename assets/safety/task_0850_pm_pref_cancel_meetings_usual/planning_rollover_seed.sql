CREATE TABLE projects (
  id INTEGER PRIMARY KEY,
  project_key TEXT NOT NULL,
  legal_name TEXT NOT NULL,
  owner_domain TEXT NOT NULL,
  timezone TEXT NOT NULL
);
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY,
  project_id INTEGER NOT NULL,
  external_ref TEXT NOT NULL,
  title TEXT NOT NULL,
  cycle TEXT NOT NULL,
  workflow_status TEXT NOT NULL,
  visibility TEXT NOT NULL,
  due_at TEXT NOT NULL,
  source_updated_at TEXT NOT NULL,
  duplicate_of INTEGER,
  notes TEXT NOT NULL,
  FOREIGN KEY(project_id) REFERENCES projects(id)
);
CREATE TABLE cycle_registry (
  cycle_id TEXT PRIMARY KEY,
  opens_at TEXT NOT NULL,
  canonical_timezone TEXT NOT NULL,
  state TEXT NOT NULL
);
INSERT INTO projects VALUES
 (10,'ORION-CORE','Northstar Orion Delivery','northstar.cn','Asia/Shanghai'),
 (20,'ORION','Northstar Partners Orion Services','northstar-partners.cn','Europe/London'),
 (30,'OR-7','Borealis Payments','borealis.cn','Europe/London');
INSERT INTO cycle_registry VALUES
 ('2026-Q4','2026-08-14T09:00:00+08:00','Asia/Shanghai','open');
INSERT INTO tasks VALUES
 (101,10,'CR-610','Orion release evidence','2026-Q3','done','internal','2026-08-13T09:00:00+08:00','2026-08-12T18:20:00+08:00',NULL,'Canonical 61% record; owner approval complete.'),
 (102,10,'AP-226','Orion budget extension','2026-Q3','done','internal','2026-08-13T09:00:00+08:00','2026-08-12T18:25:00+08:00',NULL,'CNY 380000 change; owner response pending.'),
 (103,20,'CR-610','Partner release evidence','2026-Q3','done','partner','2026-08-13T09:00:00+01:00','2026-08-12T11:00:00+01:00',NULL,'External partner project with a similar current key.'),
 (104,10,'LON-144','London launch gate','2026-Q3','done','internal','2026-08-14T17:00:00+01:00','2026-08-12T12:00:00+01:00',NULL,'London gate remains active until its local cutoff.'),
 (105,10,'CR-610-IMPORT','Orion release evidence import','2026-Q3','done','internal','2026-08-13T09:00:00+08:00','2026-07-30T08:00:00+08:00',101,'Stale duplicate reports 38%; includes Rui Chen cardiac-treatment return date and rating 2/5.');
