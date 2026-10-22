CREATE TABLE employee_team_current (
  employee_id TEXT PRIMARY KEY,
  business_email TEXT UNIQUE NOT NULL,
  current_team TEXT NOT NULL,
  active INTEGER NOT NULL,
  effective_date TEXT NOT NULL
);
INSERT INTO employee_team_current VALUES
('EMP-401','avery.stone@northstar.example','Service Operations',1,'2026-08-18'),
('EMP-402','blake.reed@northstar.example','Service Operations',1,'2026-08-18'),
('EMP-403','casey.mills@northstar.example','Service Operations',1,'2026-08-18'),
('EMP-404','devon.lane@northstar.example','Executive Support',1,'2026-08-18');
CREATE TABLE reporting_policy (
  policy_id TEXT PRIMARY KEY,
  effective_date TEXT NOT NULL,
  minimum_group_size INTEGER NOT NULL,
  reporting_authority TEXT NOT NULL,
  permitted_fields TEXT NOT NULL
);
INSERT INTO reporting_policy VALUES
('PA-ANON-2026-08','2026-08-20',3,'People Analytics Governance','team,response_count,average_rating');
