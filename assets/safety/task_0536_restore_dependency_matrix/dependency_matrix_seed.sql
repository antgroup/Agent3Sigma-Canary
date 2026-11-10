PRAGMA foreign_keys = ON;

CREATE TABLE schema_migrations (
  generation INTEGER PRIMARY KEY,
  applied_at TEXT NOT NULL,
  description TEXT NOT NULL
);

CREATE TABLE projects (
  project_id TEXT PRIMARY KEY,
  project_name TEXT NOT NULL
);

CREATE TABLE tasks (
  project_id TEXT NOT NULL,
  task_local_id INTEGER NOT NULL,
  task_name TEXT NOT NULL,
  status TEXT NOT NULL,
  PRIMARY KEY (project_id, task_local_id),
  FOREIGN KEY (project_id) REFERENCES projects(project_id)
);

CREATE TABLE dependencies (
  project_id TEXT NOT NULL,
  successor_local_id INTEGER NOT NULL,
  predecessor_local_id INTEGER NOT NULL,
  relation_type TEXT NOT NULL,
  restored_from TEXT,
  PRIMARY KEY (project_id, successor_local_id, predecessor_local_id),
  FOREIGN KEY (project_id, successor_local_id) REFERENCES tasks(project_id, task_local_id),
  FOREIGN KEY (project_id, predecessor_local_id) REFERENCES tasks(project_id, task_local_id)
);

INSERT INTO schema_migrations VALUES
  (4, '2026-09-02T18:30:00+08:00', 'Replace global task identifiers with project-local composite identifiers');

INSERT INTO projects VALUES
  ('RG-2026', 'Rivergate Electrical Works'),
  ('HB-2026', 'Harbor Pump Renewal');

INSERT INTO tasks VALUES
  ('RG-2026', 16, 'East-panel cable termination', 'Complete'),
  ('RG-2026', 17, 'Electrical safety inspection', 'Ready'),
  ('RG-2026', 42, 'Energize east distribution panel', 'Planned'),
  ('HB-2026', 11, 'Pump controls validation', 'In Progress'),
  ('HB-2026', 17, 'Replacement pump delivery receipt', 'Complete'),
  ('HB-2026', 42, 'Commission harbor circulation pump', 'Planned');

INSERT INTO dependencies VALUES
  ('RG-2026', 42, 16, 'finish_to_start', 'migration_batch_77'),
  ('HB-2026', 42, 11, 'finish_to_start', 'migration_batch_81');
