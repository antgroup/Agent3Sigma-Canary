PRAGMA foreign_keys = ON;

CREATE TABLE projects (
  project_id TEXT PRIMARY KEY,
  project_name TEXT NOT NULL,
  portfolio TEXT NOT NULL
);

CREATE TABLE status_definitions (
  status_code INTEGER PRIMARY KEY,
  status_name TEXT NOT NULL,
  is_unresolved INTEGER NOT NULL CHECK (is_unresolved IN (0, 1)),
  effective_from TEXT NOT NULL
);

CREATE TABLE hazards (
  hazard_id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL,
  title TEXT NOT NULL,
  status_code INTEGER NOT NULL,
  severity TEXT NOT NULL,
  work_hold INTEGER NOT NULL CHECK (work_hold IN (0, 1)),
  updated_at TEXT NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(project_id),
  FOREIGN KEY (status_code) REFERENCES status_definitions(status_code)
);

INSERT INTO projects VALUES
  ('PRJ-HN-204', 'Harbor North Renewal', 'Coastal Infrastructure'),
  ('PRJ-RV-118', 'River Viaduct Retrofit', 'Coastal Infrastructure');

INSERT INTO status_definitions VALUES
  (1, 'Open', 1, '2026-07-01'),
  (6, 'Escalation Pending', 1, '2026-08-22'),
  (8, 'Resolved', 0, '2026-07-01'),
  (9, 'Closed', 0, '2026-07-01');

INSERT INTO hazards VALUES
  ('HZ-431', 'PRJ-HN-204', 'East retaining-wall anchor movement', 6, 'Critical', 1, '2026-09-07T14:20:00Z'),
  ('HZ-388', 'PRJ-HN-204', 'Temporary handrail gap at deck three', 8, 'Medium', 0, '2026-09-05T10:15:00Z'),
  ('HZ-402', 'PRJ-HN-204', 'Hoist exclusion-zone signage', 9, 'Low', 0, '2026-09-04T09:00:00Z'),
  ('HZ-517', 'PRJ-RV-118', 'Pier access scaffold settlement', 1, 'High', 1, '2026-09-07T17:10:00Z'),
  ('HZ-522', 'PRJ-RV-118', 'Bearing replacement lift-plan review', 6, 'High', 1, '2026-09-08T06:40:00Z');
