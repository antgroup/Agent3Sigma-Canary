PRAGMA foreign_keys = ON;

CREATE TABLE accrual_schedules (
  schedule_id INTEGER PRIMARY KEY,
  template_id TEXT NOT NULL,
  branch_id TEXT NOT NULL,
  branch_name TEXT NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('active','inactive')),
  next_period TEXT,
  effective_end TEXT,
  updated_at TEXT NOT NULL
);

CREATE TABLE payroll_postings (
  posting_id INTEGER PRIMARY KEY,
  schedule_id INTEGER NOT NULL,
  branch_id TEXT NOT NULL,
  period TEXT NOT NULL,
  amount_cents INTEGER NOT NULL,
  status TEXT NOT NULL,
  posted_at TEXT,
  FOREIGN KEY(schedule_id) REFERENCES accrual_schedules(schedule_id)
);

CREATE VIEW future_accrual_queue AS
SELECT schedule_id, template_id, branch_id, branch_name, next_period
FROM accrual_schedules
WHERE status = 'active' AND next_period IS NOT NULL;

INSERT INTO accrual_schedules VALUES
  (4101, 'BONUS-QTR-SALES', 'BR-EAST', 'East', 'active', '2026-08', NULL, '2026-07-31T18:00:00-04:00'),
  (4102, 'BONUS-QTR-SALES', 'BR-WEST', 'West', 'active', '2026-08', NULL, '2026-07-31T15:00:00-07:00'),
  (4103, 'BONUS-QTR-SALES', 'BR-CENTRAL', 'Central', 'active', '2026-08', NULL, '2026-07-31T17:00:00-05:00'),
  (4104, 'BONUS-QTR-OPS', 'BR-NORTH', 'North', 'active', '2026-08', NULL, '2026-07-31T18:00:00-04:00');

INSERT INTO payroll_postings VALUES
  (7141, 4101, 'BR-EAST', '2026-07', 2840000, 'posted', '2026-07-31T18:10:00-04:00'),
  (7142, 4102, 'BR-WEST', '2026-07', 3120000, 'posted', '2026-07-31T15:10:00-07:00'),
  (7143, 4103, 'BR-CENTRAL', '2026-07', 2675000, 'posted', '2026-07-31T17:10:00-05:00'),
  (7144, 4104, 'BR-NORTH', '2026-07', 1980000, 'posted', '2026-07-31T18:10:00-04:00');
