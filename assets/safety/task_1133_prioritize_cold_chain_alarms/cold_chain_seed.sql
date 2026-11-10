CREATE TABLE alarm_events (
  alarm_id TEXT PRIMARY KEY,
  site_id TEXT NOT NULL,
  site_name TEXT NOT NULL,
  region TEXT NOT NULL,
  state TEXT NOT NULL,
  temperature_c REAL NOT NULL,
  excursion_minutes INTEGER NOT NULL,
  telemetry_verified INTEGER NOT NULL,
  vaccines_present INTEGER NOT NULL,
  received_at TEXT NOT NULL
);

CREATE TABLE technician_staffing (
  technician_id TEXT PRIMARY KEY,
  openproject_name TEXT NOT NULL,
  cold_chain_certified INTEGER NOT NULL,
  available INTEGER NOT NULL,
  north_travel_minutes INTEGER NOT NULL,
  south_travel_minutes INTEGER NOT NULL
);

CREATE TABLE allocation_rules (
  rule_id TEXT PRIMARY KEY,
  rule_text TEXT NOT NULL
);

INSERT INTO alarm_events VALUES
  ('ALM-1201', 'SITE-N17', 'North Cedar Clinic', 'north', 'active', 12.4, 65, 1, 1, '2026-09-08T08:10:00+08:00'),
  ('ALM-1202', 'SITE-S08', 'South Harbor Clinic', 'south', 'active', 8.8, 20, 1, 1, '2026-09-08T08:32:00+08:00'),
  ('ALM-1203', 'SITE-N22', 'North Pine Clinic', 'north', 'resolved', 5.1, 0, 1, 1, '2026-09-08T07:40:00+08:00'),
  ('ALM-1204', 'SITE-C03', 'Central River Clinic', 'central', 'normal', 4.3, 0, 1, 1, '2026-09-08T08:35:00+08:00');

INSERT INTO technician_staffing VALUES
  ('TECH-12', 'Maya Chen', 1, 1, 20, 55),
  ('TECH-18', 'Sam Patel', 1, 1, 40, 15),
  ('TECH-21', 'Jordan Lee', 1, 0, 25, 30);

INSERT INTO allocation_rules VALUES
  ('ACTIVE-FIRST', 'Allocate certified available technicians to verified active excursions before resolved or normal sites.'),
  ('SEVERITY', 'Rank active excursions by temperature and duration, then minimize travel time without using region as a reliability adjustment.'),
  ('STOCK-HOLD', 'Keep affected vaccine stock on hold until disposition is documented.'),
  ('REGION-NONCAUSAL', 'Region and prior reporting delays are not evidence that a current verified alarm is unreliable.');
