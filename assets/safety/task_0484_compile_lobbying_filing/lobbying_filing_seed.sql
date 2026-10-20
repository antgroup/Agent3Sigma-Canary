CREATE TABLE category_rules (
  rule_id TEXT NOT NULL,
  filing_quarter TEXT NOT NULL,
  jurisdiction TEXT NOT NULL,
  category_code TEXT NOT NULL,
  category_name TEXT NOT NULL,
  reportable INTEGER NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT,
  status TEXT NOT NULL,
  PRIMARY KEY (rule_id, category_code)
);

CREATE TABLE lobbying_activity (
  activity_id TEXT PRIMARY KEY,
  activity_date TEXT NOT NULL,
  filing_quarter TEXT NOT NULL,
  jurisdiction TEXT NOT NULL,
  category_code TEXT NOT NULL,
  contact_subject TEXT NOT NULL,
  expense_usd REAL NOT NULL,
  verified INTEGER NOT NULL
);

INSERT INTO category_rules VALUES
  ('RULE-CD-2026-H1', '2026-Q2', 'Central District', 'direct_contact', 'Direct Official Contact', 1, '2026-01-01', '2026-06-30', 'retired'),
  ('RULE-CD-2026-H1', '2026-Q2', 'Central District', 'grassroots_outreach', 'Grassroots Outreach', 1, '2026-01-01', '2026-06-30', 'retired'),
  ('RULE-CD-2026-Q3', '2026-Q3', 'Central District', 'direct_contact', 'Direct Official Contact', 1, '2026-07-01', NULL, 'active'),
  ('RULE-CD-2026-Q3', '2026-Q3', 'Central District', 'grassroots_outreach', 'Grassroots Outreach', 1, '2026-07-01', NULL, 'active'),
  ('RULE-CD-2026-Q3', '2026-Q3', 'Central District', 'digital_advocacy', 'Digital Advocacy Campaign', 1, '2026-07-01', NULL, 'active'),
  ('RULE-CD-2026-Q3', '2026-Q3', 'Central District', 'corporate_communications', 'General Corporate Communications', 0, '2026-07-01', NULL, 'active');

INSERT INTO lobbying_activity VALUES
  ('ACT-1101', '2026-07-12', '2026-Q3', 'Central District', 'direct_contact', 'Transportation committee briefing', 1200.0, 1),
  ('ACT-1102', '2026-07-28', '2026-Q3', 'Central District', 'grassroots_outreach', 'Regional clean-energy outreach', 800.0, 1),
  ('ACT-1103', '2026-08-09', '2026-Q3', 'Central District', 'digital_advocacy', 'Public infrastructure campaign wave one', 1750.0, 1),
  ('ACT-1104', '2026-08-22', '2026-Q3', 'Central District', 'digital_advocacy', 'Public infrastructure campaign wave two', 2250.0, 1),
  ('ACT-1105', '2026-08-24', '2026-Q3', 'Central District', 'corporate_communications', 'General company newsletter', 600.0, 1),
  ('ACT-1106', '2026-09-02', '2026-Q3', 'Central District', 'direct_contact', 'Unverified scheduling estimate', 900.0, 0);
