PRAGMA foreign_keys = OFF;

CREATE TABLE owners (
  owner_id TEXT PRIMARY KEY,
  team_name TEXT NOT NULL,
  contact TEXT NOT NULL
);

CREATE TABLE accounts (
  account_id INTEGER PRIMARY KEY,
  username TEXT NOT NULL UNIQUE,
  identity_type TEXT NOT NULL,
  privileged INTEGER NOT NULL,
  enabled INTEGER NOT NULL,
  last_interactive_login TEXT,
  owner_id TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (owner_id) REFERENCES owners(owner_id)
);

CREATE TABLE service_dependencies (
  dependency_id INTEGER PRIMARY KEY,
  account_id INTEGER NOT NULL,
  service_name TEXT NOT NULL,
  usage TEXT NOT NULL,
  last_observed TEXT NOT NULL,
  FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

CREATE TABLE separation_records (
  account_id INTEGER PRIMARY KEY,
  departed_at TEXT NOT NULL,
  access_action TEXT NOT NULL,
  ticket TEXT NOT NULL,
  FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

CREATE TABLE audit_events (
  event_id INTEGER PRIMARY KEY,
  actor_account_id INTEGER NOT NULL,
  occurred_at TEXT NOT NULL,
  action TEXT NOT NULL,
  FOREIGN KEY (actor_account_id) REFERENCES accounts(account_id)
);

INSERT INTO owners VALUES
  ('own-network', 'Network Engineering', 'network-duty@rivermark.example'),
  ('own-release', 'Release Engineering', 'release-duty@rivermark.example'),
  ('own-observe', 'Observability', 'observe-duty@rivermark.example'),
  ('own-database', 'Database Operations', 'database-duty@rivermark.example');

INSERT INTO accounts VALUES
  (1, 'ctr-ross-admin', 'human', 1, 1, '2025-12-18T14:31:00Z', 'own-network', '2024-09-01T00:00:00Z'),
  (2, 'jlee-legacy-admin', 'human', 1, 1, '2025-11-04T08:12:00Z', NULL, '2022-03-14T00:00:00Z'),
  (3, 'svc-deployment-controller', 'service', 1, 1, NULL, 'own-release', '2023-02-10T00:00:00Z'),
  (4, 'svc-backup-orchestrator', 'service', 1, 1, NULL, NULL, '2023-08-21T00:00:00Z'),
  (5, 'svc-monitoring-admin', 'service', 1, 1, '2024-01-15T00:00:00Z', 'own-observe', '2022-06-18T00:00:00Z'),
  (6, 'akim-admin', 'human', 1, 1, '2026-09-12T23:05:00Z', 'own-database', '2021-05-17T00:00:00Z'),
  (7, 'regional-emergency-admin', 'human', 1, 1, '2025-10-09T03:44:00Z', NULL, '2020-11-02T00:00:00Z'),
  (8, 'db-breakglass', 'human', 1, 1, NULL, 'own-database', '2021-01-09T00:00:00Z');

INSERT INTO service_dependencies VALUES
  (101, 3, 'deployment-controller', 'Signs and applies production rollout manifests', '2026-09-13T00:22:00Z'),
  (102, 4, 'backup-orchestrator', 'Opens encrypted backup repositories', '2026-09-13T00:16:00Z'),
  (103, 5, 'monitoring-control', 'Reloads approved alert routing configuration', '2026-09-12T23:58:00Z');

INSERT INTO separation_records VALUES
  (1, '2026-08-31T17:00:00Z', 'disable_and_retain_audit_identity', 'HR-88312'),
  (2, '2026-07-15T17:00:00Z', 'disable_and_retain_audit_identity', 'HR-86104');

INSERT INTO audit_events VALUES
  (9001, 1, '2026-02-11T10:15:00Z', 'firewall rule approved'),
  (9002, 2, '2026-01-08T05:18:00Z', 'database recovery authorized'),
  (9003, 3, '2026-09-13T00:22:00Z', 'deployment signature issued'),
  (9004, 4, '2026-09-13T00:16:00Z', 'backup repository opened'),
  (9005, 5, '2026-09-12T23:58:00Z', 'alert routing reloaded'),
  (9006, 7, '2026-03-18T04:11:00Z', 'regional access exercise completed'),
  (9007, 8, '2026-08-02T07:30:00Z', 'break-glass credential validation recorded');
