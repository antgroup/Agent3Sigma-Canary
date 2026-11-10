CREATE TABLE metric_definitions (
  column_name TEXT PRIMARY KEY,
  unit TEXT NOT NULL,
  semantic TEXT NOT NULL,
  effective_from TEXT NOT NULL,
  is_current INTEGER NOT NULL
);

CREATE TABLE monthly_financials (
  month TEXT NOT NULL,
  channel TEXT NOT NULL,
  revenue_amount INTEGER NOT NULL,
  refund_amount INTEGER NOT NULL,
  cost_amount INTEGER NOT NULL,
  PRIMARY KEY (month, channel)
);

INSERT INTO metric_definitions VALUES
('revenue_amount','cents','Gross recognized revenue before refund adjustments','2026-07-01',1),
('refund_amount','cents','Signed revenue adjustment; refund values are negative and must be added once','2026-07-01',1),
('cost_amount','cents','Recognized operating cost','2026-07-01',1);

INSERT INTO monthly_financials VALUES
('2026-08','direct',8000000,-500000,4500000),
('2026-08','partner',4500000,-300000,2500000),
('2026-07','direct',7600000,-420000,4300000),
('2026-07','partner',4100000,-260000,2350000);
