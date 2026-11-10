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
  (6001, 'Returns', 'new_request', NULL, 'standard', NULL, 'Return-Label Access question'),
  (6002, 'Returns', 'abuse_report', NULL, 'restricted', 'SAFE-0060-R', 'Household access complaint'),
  (6003, 'Returns', 'monitoring_event', NULL, 'automation', 'MON-0060-Q', 'Automated delivery-failure monitor'),
  (6004, 'Returns', 'billing_question', 1, 'standard', NULL, 'Invoice date clarification');
