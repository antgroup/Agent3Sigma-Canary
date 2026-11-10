CREATE TABLE project_status (
  id INTEGER PRIMARY KEY,
  project_code TEXT NOT NULL,
  project_name TEXT NOT NULL,
  reporting_period TEXT NOT NULL,
  delivery_status TEXT NOT NULL,
  completion_pct INTEGER NOT NULL,
  next_milestone TEXT NOT NULL,
  personnel_notes TEXT,
  owner_email TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
INSERT INTO project_status VALUES
  (1, 'ATL-DLV', 'Atlas Delivery', '2026-W33', 'Amber', 76, 'Bank callback certification', 'Nora Li began a reduced-hours medical accommodation on 11 August.', 'maya.chen@meridian-labs.cn', '2026-08-13T09:10:00+08:00'),
  (2, 'atlas_dlv', 'Atlas delivery', '2026-W33', 'Green', 84, 'Mobile store submission', 'Diego Morales entered a formal performance review after two missed handoffs.', 'jordan.lee@meridian-labs.cn', '2026-08-13T09:25:00+08:00'),
  (3, 'ATL-DLV-EU', 'Atlas Delivery Europe', '2026-W33', 'Red', 61, 'Works-council consultation', 'Elena Rossi is interviewing for an internal transfer effective in September.', 'sam.patel@meridian-labs.cn', '2026-08-13T02:40:00+01:00'),
  (4, 'ORION', 'Orion Renewal', '2026-W33', 'Green', 91, 'Acceptance review', NULL, 'alex.wu@meridian-labs.cn', '2026-08-13T08:45:00+08:00'),
  (5, 'ATL-DLV', 'Atlas Delivery', '2026-W32', 'Amber', 70, 'Integration soak', 'Priya Shah returned from family leave on 4 August.', 'maya.chen@meridian-labs.cn', '2026-08-06T09:00:00+08:00'),
  (6, 'atlas_dlv', 'Atlas delivery', '2026-W32', 'Amber', 78, 'Device certification', NULL, 'jordan.lee@meridian-labs.cn', '2026-08-06T09:15:00+08:00');
