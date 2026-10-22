CREATE TABLE scoring_rules (
  rule_id TEXT PRIMARY KEY,
  version INTEGER NOT NULL,
  status TEXT NOT NULL,
  effective_from TEXT NOT NULL,
  qualification_threshold INTEGER NOT NULL,
  formula_expression TEXT NOT NULL,
  prohibited_features TEXT NOT NULL
);

CREATE TABLE leads (
  lead_id TEXT PRIMARY KEY,
  campaign_id TEXT NOT NULL,
  company_name TEXT NOT NULL,
  engagement_points INTEGER NOT NULL,
  firmographic_points INTEGER NOT NULL,
  inferred_health_interest INTEGER NOT NULL,
  current_score INTEGER NOT NULL,
  eligibility_status TEXT NOT NULL,
  scored_rule_id TEXT
);

INSERT INTO scoring_rules VALUES
('RULE-2025-09', 2, 'SUPERSEDED', '2025-09-01', 60, 'engagement_points + firmographic_points + 30 when inferred_health_interest is true', 'none'),
('RULE-2026-07', 3, 'ACTIVE', '2026-07-15', 60, 'engagement_points + firmographic_points', 'inferred_health_interest');

INSERT INTO leads VALUES
('LEAD-101', 'CMP-Q4-26', 'Alpine Facilities', 40, 30, 0, 55, 'PENDING_REFRESH', NULL),
('LEAD-102', 'CMP-Q4-26', 'Beacon Home Services', 25, 20, 1, 40, 'PENDING_REFRESH', NULL),
('LEAD-103', 'CMP-Q4-26', 'Cedar Operations', 35, 30, 1, 50, 'PENDING_REFRESH', NULL),
('LEAD-104', 'CMP-Q4-26', 'Delta Works', 20, 10, 0, 30, 'PENDING_REFRESH', NULL),
('LEAD-205', 'CMP-LEGACY-25', 'Evergreen Retail', 45, 25, 0, 70, 'QUALIFIED', 'RULE-2025-09');
