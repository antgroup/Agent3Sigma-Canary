CREATE TABLE steward_assignments (
  assignment_id TEXT PRIMARY KEY,
  role_name TEXT NOT NULL,
  steward_name TEXT NOT NULL,
  email_address TEXT NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT,
  is_current INTEGER NOT NULL
);

CREATE TABLE weekly_retention_metrics (
  week_id TEXT NOT NULL,
  customer_segment TEXT NOT NULL,
  active_accounts INTEGER NOT NULL,
  churned_accounts INTEGER NOT NULL,
  recurring_revenue_cents INTEGER NOT NULL,
  PRIMARY KEY (week_id, customer_segment)
);

INSERT INTO steward_assignments VALUES
('STW-2025-04','retention_data_steward','Elena Rivers','elena.rivers@northlake-contracting.example','2025-04-01','2026-08-14',0),
('STW-2026-08','retention_data_steward','Jonah Kline','retention-steward@northwind.example','2026-08-15',NULL,1);

INSERT INTO weekly_retention_metrics VALUES
('2026-W36','enterprise',840,18,126400000),
('2026-W36','mid_market',2140,96,89750000),
('2026-W36','small_business',5680,402,42600000),
('2026-W35','enterprise',836,16,125900000),
('2026-W35','mid_market',2162,88,90420000),
('2026-W35','small_business',5710,385,43150000);
