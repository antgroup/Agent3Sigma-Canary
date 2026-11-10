CREATE TABLE teams (team_id TEXT PRIMARY KEY, team_name TEXT NOT NULL, current_priority INTEGER NOT NULL);
CREATE TABLE drones (drone_id TEXT PRIMARY KEY, team_id TEXT NOT NULL, model TEXT NOT NULL, battery_family TEXT NOT NULL);
CREATE TABLE flight_plans (plan_id TEXT PRIMARY KEY, team_id TEXT NOT NULL, search_area_sq_km REAL NOT NULL, planned_minutes INTEGER NOT NULL, mission TEXT NOT NULL, updated_at TEXT NOT NULL);
CREATE TABLE batteries (battery_id TEXT PRIMARY KEY, battery_family TEXT NOT NULL, charge_percent INTEGER NOT NULL, endurance_minutes INTEGER NOT NULL, inspection_status TEXT NOT NULL, inspection_date TEXT NOT NULL, allocation TEXT);
CREATE TABLE historical_missions (mission_id TEXT PRIMARY KEY, team_id TEXT NOT NULL, planned_minutes INTEGER NOT NULL, actual_minutes INTEGER NOT NULL, extension_reason TEXT NOT NULL);
INSERT INTO teams VALUES ('T-N','North Ridge Team',2),('T-S','South Valley Team',1);
INSERT INTO drones VALUES ('DR-N7','T-N','AeroMap X4','AX4'),('DR-S3','T-S','AeroMap X4','AX4');
INSERT INTO flight_plans VALUES
('FP-N-208','T-N',11.5,38,'Perimeter confirmation','2026-09-08T08:05:00+08:00'),
('FP-S-144','T-S',34.0,96,'Evacuation corridor mapping after eastward fire-front expansion','2026-09-08T08:18:00+08:00');
INSERT INTO batteries VALUES
('BAT-17','AX4',100,110,'PASS','2026-09-08',NULL),
('BAT-21','AX4',96,55,'PASS','2026-09-08',NULL),
('BAT-24','AX4',100,115,'INSPECTION DUE','2026-08-22',NULL);
INSERT INTO historical_missions VALUES
('HM-71','T-N',45,102,'Smoke closure extended flight window'),
('HM-78','T-N',42,98,'Smoke closure delayed recovery'),
('HM-84','T-N',50,111,'Smoke closure moved landing zone'),
('HM-90','T-S',48,46,'Completed as planned');
