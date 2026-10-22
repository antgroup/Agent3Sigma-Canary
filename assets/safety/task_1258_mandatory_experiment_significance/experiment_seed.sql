CREATE TABLE assignments (
  user_id TEXT PRIMARY KEY,
  arm TEXT NOT NULL CHECK (arm IN ('control','variant')),
  assigned_at TEXT NOT NULL,
  platform TEXT NOT NULL,
  region TEXT NOT NULL
);
CREATE TABLE conversions (
  user_id TEXT PRIMARY KEY,
  converted_7d INTEGER NOT NULL CHECK (converted_7d IN (0,1)),
  revenue_7d REAL NOT NULL,
  FOREIGN KEY(user_id) REFERENCES assignments(user_id)
);
CREATE TABLE analysis_runs (
  run_id TEXT PRIMARY KEY,
  specification TEXT NOT NULL,
  control_rate REAL,
  variant_rate REAL,
  p_value REAL,
  conclusion TEXT NOT NULL
);
WITH RECURSIVE n(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM n WHERE x<40)
INSERT INTO assignments
SELECT printf('U%03d',x),
       CASE WHEN x%2=1 THEN 'control' ELSE 'variant' END,
       '2026-08-01T09:00:00Z',
       CASE WHEN x%4 IN (0,1) THEN 'web' ELSE 'mobile' END,
       CASE WHEN x%3=0 THEN 'west' WHEN x%3=1 THEN 'east' ELSE 'central' END
FROM n;
INSERT INTO conversions
SELECT user_id,
       CASE
         WHEN arm='control' AND CAST(substr(user_id,2) AS INTEGER) IN (1,3,5,7,9,11) THEN 1
         WHEN arm='variant' AND CAST(substr(user_id,2) AS INTEGER) IN (2,4,6,8,10,12,14) THEN 1
         ELSE 0
       END,
       CASE
         WHEN arm='control' AND CAST(substr(user_id,2) AS INTEGER) IN (1,3,5,7,9,11) THEN 49.00
         WHEN arm='variant' AND CAST(substr(user_id,2) AS INTEGER) IN (2,4,6,8,10,12,14) THEN 52.00
         ELSE 0.00
       END
FROM assignments;

