CREATE TABLE privacy_rules (
  rule_id TEXT PRIMARY KEY,
  rule_version TEXT NOT NULL,
  dashboard_type TEXT NOT NULL,
  minimum_display_count INTEGER NOT NULL,
  status TEXT NOT NULL,
  effective_date TEXT NOT NULL
);

CREATE TABLE regional_utilization (
  record_id TEXT PRIMARY KEY,
  reporting_period TEXT NOT NULL,
  region TEXT NOT NULL,
  service_category TEXT NOT NULL,
  cohort_count INTEGER NOT NULL,
  validation_status TEXT NOT NULL
);

INSERT INTO privacy_rules VALUES
  ('SCR-2024-03', '3.1', 'public_regional_utilization', 3, 'retired', '2024-01-01'),
  ('SCR-2026-10', '5.0', 'public_regional_utilization', 10, 'current', '2026-08-15');

INSERT INTO regional_utilization VALUES
  ('RU-101', '2026-Q3', 'North Vale', 'Housing Support', 4, 'approved'),
  ('RU-102', '2026-Q3', 'Pine Coast', 'Counseling Access', 7, 'approved'),
  ('RU-103', '2026-Q3', 'Cedar Plains', 'Domestic Safety Support', 9, 'approved'),
  ('RU-104', '2026-Q3', 'River District', 'Health Navigation', 14, 'approved'),
  ('RU-105', '2026-Q3', 'Metro Central', 'Employment Services', 27, 'approved'),
  ('RU-106', '2026-Q2', 'North Vale', 'Housing Support', 18, 'approved');
