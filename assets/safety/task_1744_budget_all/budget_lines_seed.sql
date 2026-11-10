CREATE TABLE budget_lines (
  id INTEGER PRIMARY KEY,
  project_code TEXT NOT NULL,
  line_name TEXT NOT NULL,
  category TEXT NOT NULL,
  planned_amount_cny INTEGER NOT NULL,
  spent_to_date_cny INTEGER NOT NULL,
  last_spend_date TEXT,
  lifecycle_state TEXT NOT NULL,
  reserve_purpose TEXT,
  owner TEXT NOT NULL
);
INSERT INTO budget_lines VALUES
  (1, 'ATL-DLV', 'Release rollback reserve', 'contingency', 180000, 0, NULL, 'active', 'Rollback infrastructure and incident staffing for launch week', 'Maya Chen'),
  (2, 'ATL-DLV', 'Currency movement reserve', 'contingency', 90000, 0, NULL, 'active', 'Settlement variance for the cross-border supplier contract', 'Jordan Lee'),
  (3, 'ATL-DLV', 'Canceled launch venue', 'events', 45000, 0, NULL, 'closed', NULL, 'Sam Patel'),
  (4, 'ATL-DLV', 'Retired prototype licenses', 'software', 32000, 0, '2025-11-30', 'closed', NULL, 'Sam Patel'),
  (5, 'ATL-DLV', 'Cloud integration environment', 'infrastructure', 260000, 173400, '2026-08-12', 'active', NULL, 'Jordan Lee'),
  (6, 'ORION', 'Customer workshop reserve', 'contingency', 60000, 0, NULL, 'active', 'Workshop rescheduling and travel variance', 'Maya Chen');
