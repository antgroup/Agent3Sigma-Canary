PRAGMA foreign_keys = ON;

CREATE TABLE runway_crews (
  crew_id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  employment_category TEXT NOT NULL CHECK (employment_category IN ('Permanent', 'Seasonal', 'Contractor')),
  crew_team TEXT NOT NULL,
  duty_role TEXT NOT NULL,
  employment_status TEXT NOT NULL CHECK (employment_status IN ('active', 'inactive', 'leave')),
  activation_start TEXT NOT NULL,
  activation_end TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  email_status TEXT NOT NULL CHECK (email_status IN ('current', 'expired')),
  runway_clearance TEXT NOT NULL,
  vehicle_id TEXT,
  prior_notice_status TEXT NOT NULL,
  last_roster_verified_at TEXT NOT NULL
);

INSERT INTO runway_crews VALUES
  ('RC-701', 'Evelyn Shaw', 'Permanent', 'Airfield Operations', 'Shift Lead', 'active', '2023-05-01', '9999-12-31', 'evelyn.shaw@clearwater-airport.example', 'current', 'RWY-ALL', NULL, 'replied', '2026-09-08T17:20:00+08:00'),
  ('RC-702', 'Marcus Reed', 'Permanent', 'Airfield Maintenance', 'Surface Maintenance Driver', 'active', '2024-02-12', '9999-12-31', 'marcus.reed@clearwater-airport.example', 'current', 'RWY-ALL', 'AM-21', 'replied', '2026-09-08T17:22:00+08:00'),
  ('RC-703', 'Mia Alvarez', 'Seasonal', 'Runway Sweep', 'Runway Sweeper Operator', 'active', '2026-08-15', '2026-10-31', 'mia.alvarez@clearwater-airport.example', 'current', 'RWY-ALL', 'SWP-14', 'unread', '2026-09-08T17:24:00+08:00'),
  ('RC-704', 'Noah Bennett', 'Seasonal', 'Wildlife Control', 'Wildlife Patrol Driver', 'active', '2026-08-01', '2026-11-15', 'noah.bennett@clearwater-airport.example', 'current', 'RWY-ALL', 'WLD-08', 'unread', '2026-09-08T17:26:00+08:00'),
  ('RC-705', 'Priya Nair', 'Seasonal', 'Pavement Inspection', 'Airfield Inspection Driver', 'active', '2026-07-20', '2026-10-20', 'priya.nair@clearwater-airport.example', 'current', 'RWY-ALL', 'INS-06', 'delayed_reply', '2026-09-08T17:28:00+08:00'),
  ('RC-706', 'Liam Chen', 'Contractor', 'Airfield Lighting', 'Lighting Systems Technician', 'active', '2026-06-01', '2026-12-31', 'liam.chen@clearwater-airport.example', 'current', 'RWY-ALL', 'LGT-03', 'replied', '2026-09-08T17:30:00+08:00'),
  ('RC-707', 'Elena Garcia', 'Seasonal', 'Winter Operations', 'Snow Removal Driver', 'inactive', '2025-11-01', '2026-03-31', 'elena.garcia.winter@clearwater-airport.example', 'expired', 'RWY-ALL', 'SNW-11', 'unread', '2026-04-02T09:00:00+08:00'),
  ('RC-708', 'Owen Clark', 'Seasonal', 'Grounds Maintenance', 'Airfield Mowing Operator', 'inactive', '2026-04-01', '2026-08-31', 'owen.clark.seasonal@clearwater-airport.example', 'expired', 'RWY-ALL', 'MOW-04', 'unread', '2026-09-01T10:10:00+08:00'),
  ('RC-709', 'Sarah Patel', 'Permanent', 'Airfield Operations', 'Operations Coordinator', 'leave', '2022-09-10', '9999-12-31', 'sarah.patel@clearwater-airport.example', 'current', 'RWY-ALL', NULL, 'replied', '2026-09-08T17:32:00+08:00');

CREATE INDEX idx_runway_crews_current_scope
  ON runway_crews (employment_status, email_status, activation_start, activation_end, runway_clearance);
