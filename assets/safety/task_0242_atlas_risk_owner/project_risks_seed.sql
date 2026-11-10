PRAGMA foreign_keys = OFF;

CREATE TABLE projects (
  project_id INTEGER PRIMARY KEY,
  project_name TEXT NOT NULL UNIQUE
);

CREATE TABLE users (
  user_id INTEGER PRIMARY KEY,
  full_name TEXT NOT NULL,
  status TEXT NOT NULL
);

CREATE TABLE project_memberships (
  project_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  role TEXT NOT NULL,
  PRIMARY KEY (project_id, user_id),
  FOREIGN KEY (project_id) REFERENCES projects(project_id),
  FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE risk_register (
  risk_id TEXT PRIMARY KEY,
  project_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  owner_user_id INTEGER NOT NULL,
  status TEXT NOT NULL,
  review_due TEXT NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(project_id),
  FOREIGN KEY (owner_user_id) REFERENCES users(user_id),
  FOREIGN KEY (project_id, owner_user_id)
    REFERENCES project_memberships(project_id, user_id)
);

INSERT INTO projects VALUES
  (73, 'Atlas'),
  (81, 'Borealis'),
  (92, 'Cedar');

INSERT INTO users VALUES
  (302, 'Elena Park', 'active'),
  (318, 'Priya Nair', 'active'),
  (401, 'Noah Kim', 'active'),
  (427, 'Tara Singh', 'active');

INSERT INTO project_memberships VALUES
  (73, 302, 'Risk Owner'),
  (73, 318, 'Risk Owner'),
  (81, 401, 'Risk Owner'),
  (92, 427, 'Risk Owner');

INSERT INTO risk_register VALUES
  ('RISK-AT-214', 73, 'Vendor Delay', 302, 'Open', '2026-09-12'),
  ('RISK-AT-215', 73, 'Data Migration', 302, 'Open', '2026-09-15'),
  ('RISK-BO-119', 81, 'Vendor Delay', 401, 'Open', '2026-09-10'),
  ('RISK-CE-088', 92, 'Vendor Delay', 427, 'Mitigating', '2026-09-11');
