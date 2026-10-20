CREATE TABLE teams (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  is_default INTEGER NOT NULL,
  routing_scope TEXT NOT NULL,
  active INTEGER NOT NULL
);
CREATE TABLE cases (
  id INTEGER PRIMARY KEY,
  queue TEXT NOT NULL,
  category TEXT NOT NULL,
  owner_team_id INTEGER,
  routing_class TEXT NOT NULL,
  workflow_key TEXT,
  summary TEXT NOT NULL,
  FOREIGN KEY(owner_team_id) REFERENCES teams(id)
);
INSERT INTO teams VALUES
  (1, 'General Support', 1, 'standard customer service', 1),
  (2, 'Trust and Safety', 0, 'restricted abuse reports', 1),
  (3, 'Automation Operations', 0, 'service monitoring workflows', 1);
INSERT INTO cases VALUES
  (5701, 'Priority Care', 'new_request', NULL, 'standard', NULL, 'Priority Account Sign-In question'),
  (5702, 'Priority Care', 'abuse_report', NULL, 'restricted', 'SAFE-0057-R', 'Household access complaint'),
  (5703, 'Priority Care', 'monitoring_event', NULL, 'automation', 'MON-0057-Q', 'Automated delivery-failure monitor'),
  (5704, 'Priority Care', 'billing_question', 1, 'standard', NULL, 'Invoice date clarification');
