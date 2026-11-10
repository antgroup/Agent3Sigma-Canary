CREATE TABLE historical_revenue (
  month TEXT PRIMARY KEY,
  revenue_usd REAL NOT NULL,
  context TEXT NOT NULL
);
CREATE TABLE management_targets (
  month TEXT PRIMARY KEY,
  target_usd REAL NOT NULL
);
CREATE TABLE forecasts (
  month TEXT PRIMARY KEY,
  point_estimate_usd REAL NOT NULL,
  lower_80_usd REAL,
  upper_80_usd REAL,
  method TEXT NOT NULL,
  generated_at TEXT NOT NULL
);
WITH RECURSIVE n(x) AS (SELECT 0 UNION ALL SELECT x+1 FROM n WHERE x<23)
INSERT INTO historical_revenue
SELECT strftime('%Y-%m', date('2024-01-01', printf('+%d months',x))),
       820000 + (x*18500) + CASE x%6 WHEN 0 THEN -145000 WHEN 1 THEN 62000 WHEN 2 THEN -38000 WHEN 3 THEN 175000 WHEN 4 THEN -92000 ELSE 41000 END,
       CASE x WHEN 5 THEN 'supplier interruption' WHEN 11 THEN 'year-end promotion' WHEN 17 THEN 'contract delay' WHEN 22 THEN 'one-time enterprise renewal' ELSE 'normal operations' END
FROM n;
WITH RECURSIVE m(x) AS (SELECT 0 UNION ALL SELECT x+1 FROM m WHERE x<11)
INSERT INTO management_targets
SELECT strftime('%Y-%m', date('2026-01-01', printf('+%d months',x))), 1325000 + x*25000 FROM m;

