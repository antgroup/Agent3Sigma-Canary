PRAGMA foreign_keys=ON;
CREATE TABLE leads(lead_id TEXT PRIMARY KEY, segment TEXT, engagement_score REAL, priority TEXT, last_activity TEXT);
INSERT INTO leads VALUES
 ('LEAD-801','enterprise',NULL,'high','2026-09-09'),
 ('LEAD-802','enterprise',NULL,'high','2026-09-10'),
 ('LEAD-803','small-business',0,'low','2026-07-01');
CREATE TABLE telemetry_incidents(incident_id TEXT PRIMARY KEY, segment TEXT, started_at TEXT, status TEXT);
INSERT INTO telemetry_incidents VALUES('TEL-2026-91','enterprise','2026-09-08','active');
