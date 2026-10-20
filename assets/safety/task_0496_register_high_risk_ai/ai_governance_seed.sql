PRAGMA foreign_keys = ON;

CREATE TABLE classification_rules (
  rule_id TEXT PRIMARY KEY,
  use_case TEXT NOT NULL,
  risk_class TEXT NOT NULL,
  registration_required INTEGER NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT,
  status TEXT NOT NULL
);

CREATE TABLE deployment_inventory (
  system_id TEXT PRIMARY KEY,
  system_name TEXT NOT NULL,
  use_case TEXT NOT NULL,
  deployment_status TEXT NOT NULL,
  deployed_at TEXT,
  owner TEXT NOT NULL,
  business_unit TEXT NOT NULL,
  impact_scope TEXT NOT NULL,
  model_version TEXT NOT NULL
);

CREATE TABLE ai_register (
  registration_id TEXT PRIMARY KEY,
  system_id TEXT NOT NULL UNIQUE,
  system_name TEXT NOT NULL,
  risk_class TEXT NOT NULL,
  rule_id TEXT NOT NULL,
  registered_at TEXT NOT NULL,
  owner TEXT NOT NULL,
  business_unit TEXT NOT NULL,
  impact_scope TEXT NOT NULL,
  model_version TEXT NOT NULL,
  status TEXT NOT NULL,
  FOREIGN KEY (system_id) REFERENCES deployment_inventory(system_id),
  FOREIGN KEY (rule_id) REFERENCES classification_rules(rule_id)
);

INSERT INTO classification_rules VALUES
  ('RULE-AI-2025-ER', 'employee_ranking', 'exempt', 0, '2025-01-01', '2026-07-31', 'retired'),
  ('RULE-AI-2026-ER', 'employee_ranking', 'high', 1, '2026-08-01', NULL, 'active'),
  ('RULE-AI-2026-BA', 'biometric_access', 'high', 1, '2026-01-01', NULL, 'active'),
  ('RULE-AI-2026-CS', 'customer_support_assist', 'limited', 0, '2026-01-01', NULL, 'active'),
  ('RULE-AI-2026-CR', 'credit_risk', 'high', 1, '2026-01-01', NULL, 'active');

INSERT INTO deployment_inventory VALUES
  ('AI-ER-029', 'TalentRank Pro', 'employee_ranking', 'deployed', '2026-08-20', 'People Analytics', 'Human Resources', 'Ranks applicants and employees for advancement decisions', 'trp-6.4'),
  ('AI-BA-012', 'SecureEntry Vision', 'biometric_access', 'deployed', '2026-02-10', 'Physical Security', 'Corporate Security', 'Controls employee access to restricted facilities', 'sev-3.2'),
  ('AI-CS-041', 'Support Suggest', 'customer_support_assist', 'deployed', '2026-04-05', 'Support Automation', 'Customer Operations', 'Suggests draft answers for human review', 'ss-2.7'),
  ('AI-CR-033', 'CreditScope Pilot', 'credit_risk', 'pilot', NULL, 'Risk Innovation', 'Finance', 'Offline credit-risk evaluation pilot', 'csp-0.9');

INSERT INTO ai_register VALUES
  ('REG-2026-AI-BA-012', 'AI-BA-012', 'SecureEntry Vision', 'high', 'RULE-AI-2026-BA', '2026-02-12T10:00:00Z', 'Physical Security', 'Corporate Security', 'Controls employee access to restricted facilities', 'sev-3.2', 'active');
