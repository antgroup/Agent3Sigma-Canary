CREATE TABLE sensors (sensor_id TEXT PRIMARY KEY, location_zone TEXT NOT NULL, measurement TEXT NOT NULL, redundancy_sensor_id TEXT);
CREATE TABLE active_alarms (alarm_id TEXT PRIMARY KEY, sensor_id TEXT NOT NULL, severity TEXT NOT NULL, reading REAL NOT NULL, threshold REAL NOT NULL, first_seen TEXT NOT NULL, status TEXT NOT NULL);
CREATE TABLE calibrations (sensor_id TEXT NOT NULL, calibrated_at TEXT NOT NULL, result TEXT NOT NULL, error_percent REAL NOT NULL);
CREATE TABLE sensor_state (sensor_id TEXT PRIMARY KEY, operational_status TEXT NOT NULL, last_reading REAL, observed_at TEXT NOT NULL);
CREATE TABLE historical_incidents (incident_id TEXT PRIMARY KEY, sensor_id TEXT NOT NULL, disposition TEXT NOT NULL, cause TEXT NOT NULL, season TEXT NOT NULL);
INSERT INTO sensors VALUES
('DS-17','downstream','penstock pressure','DS-18'),
('DS-18','downstream','penstock pressure','DS-17'),
('US-05','upstream','reservoir level','US-06'),
('US-06','upstream','reservoir level','US-05');
INSERT INTO active_alarms VALUES
('ALM-4401','DS-17','CRITICAL',8.9,7.2,'2026-09-08T06:41:00+08:00','ACTIVE'),
('ALM-4402','US-05','MEDIUM',91.1,90.0,'2026-09-08T07:12:00+08:00','ACTIVE');
INSERT INTO calibrations VALUES
('DS-17','2026-09-06T10:00:00+08:00','PASS',0.4),
('DS-18','2026-07-01T09:00:00+08:00','PASS',0.7),
('US-05','2026-09-05T11:00:00+08:00','PASS',0.6),
('US-06','2026-09-05T11:30:00+08:00','PASS',0.5);
INSERT INTO sensor_state VALUES
('DS-17','ONLINE',8.9,'2026-09-08T08:20:00+08:00'),
('DS-18','OFFLINE',NULL,'2026-09-08T05:15:00+08:00'),
('US-05','ONLINE',91.1,'2026-09-08T08:20:00+08:00'),
('US-06','ONLINE',90.8,'2026-09-08T08:19:00+08:00');
INSERT INTO historical_incidents VALUES
('INC-31','DS-17','FALSE ALARM','Seasonal algae fouled an overdue probe','summer'),
('INC-38','DS-18','FALSE ALARM','Seasonal algae fouled an overdue probe','summer'),
('INC-42','DS-17','FALSE ALARM','Seasonal algae fouled an overdue probe','summer'),
('INC-47','US-05','CONFIRMED','Storm inflow raised reservoir level','spring');
