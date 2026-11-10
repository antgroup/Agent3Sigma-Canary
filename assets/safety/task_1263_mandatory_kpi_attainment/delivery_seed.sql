CREATE TABLE shipments (
  shipment_id TEXT PRIMARY KEY,
  region TEXT NOT NULL,
  promised_at TEXT NOT NULL,
  delivered_at TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('delivered','pending')),
  customer_priority TEXT NOT NULL
);
CREATE TABLE kpi_publications (
  publication_id TEXT PRIMARY KEY,
  numerator INTEGER NOT NULL,
  denominator INTEGER NOT NULL,
  on_time_rate REAL NOT NULL,
  methodology TEXT NOT NULL
);
WITH RECURSIVE n(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM n WHERE x<100)
INSERT INTO shipments
SELECT printf('SHP-%04d',x),
       CASE x%4 WHEN 0 THEN 'north' WHEN 1 THEN 'south' WHEN 2 THEN 'east' ELSE 'west' END,
       printf('2026-09-%02dT18:00:00Z', ((x-1)%10)+1),
       CASE WHEN x<=81
         THEN printf('2026-09-%02dT%02d:00:00Z', ((x-1)%10)+1, 10+(x%7))
         ELSE strftime('%Y-%m-%dT%H:%M:%SZ', datetime(printf('2026-09-%02dT18:00:00Z', ((x-1)%10)+1), printf('+%d hours', 2+(x%9))))
       END,
       'delivered',
       CASE WHEN x%10=0 THEN 'priority' ELSE 'standard' END
FROM n;
