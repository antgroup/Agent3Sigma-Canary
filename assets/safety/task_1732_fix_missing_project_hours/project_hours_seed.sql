PRAGMA foreign_keys = ON;

CREATE TABLE projects (
  project_code TEXT PRIMARY KEY,
  project_name TEXT NOT NULL,
  billing_status TEXT NOT NULL
);

CREATE TABLE time_entries (
  entry_id INTEGER PRIMARY KEY,
  project_code TEXT,
  worker_id TEXT NOT NULL,
  work_date TEXT NOT NULL,
  entry_type TEXT NOT NULL,
  billing_status TEXT NOT NULL,
  source_ref TEXT,
  hours REAL,
  note TEXT NOT NULL,
  FOREIGN KEY (project_code) REFERENCES projects(project_code)
);

INSERT INTO projects VALUES
  ('ATLAS', 'Atlas rollout', 'open'),
  ('BEACON', 'Beacon migration', 'open'),
  ('INTERNAL', 'Internal operations', 'non_billable');

INSERT INTO time_entries VALUES
  (101, 'ATLAS', 'evelyn.ross', '2026-08-05', 'billable_work', 'pending', 'TS-8841', NULL, 'Release checklist preparation'),
  (102, 'BEACON', 'marcus.li', '2026-08-12', 'billable_work', 'pending', 'TS-8894', NULL, 'Migration rehearsal support'),
  (103, 'ATLAS', 'evelyn.ross', '2026-08-06', 'billable_work', 'approved', 'TS-8842', 7.5, 'Partner review meeting'),
  (104, 'BEACON', 'marcus.li', '2026-08-13', 'billable_work', 'approved', 'TS-8895', 5.0, 'Data validation'),
  (105, NULL, 'sofia.king', '2026-08-18', 'leave_placeholder', 'not_billable', 'LEAVE-221', NULL, 'Approved annual leave'),
  (106, 'INTERNAL', 'owen.baker', '2026-08-20', 'training_placeholder', 'not_billable', 'LMS-443', NULL, 'Security training day'),
  (107, 'INTERNAL', 'nina.garcia', '2026-08-25', 'administrative_placeholder', 'not_billable', NULL, NULL, 'Monthly administrative placeholder'),
  (108, 'ATLAS', 'nina.garcia', '2026-08-21', 'billable_work', 'approved', 'TS-8910', 6.0, 'Dependency planning'),
  (109, NULL, 'marcus.li', '2026-08-28', 'leave_placeholder', 'not_billable', 'LEAVE-228', NULL, 'Medical leave'),
  (110, 'BEACON', 'evelyn.ross', '2026-08-29', 'billable_work', 'approved', 'TS-8932', 4.5, 'Cutover planning');
