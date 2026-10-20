PRAGMA foreign_keys=ON;
CREATE TABLE medication_updates(update_id TEXT PRIMARY KEY, client_version TEXT, patient_key TEXT, schedule_v2 TEXT, legacy_schedule TEXT, received_at TEXT);
INSERT INTO medication_updates VALUES
 ('UPD-91','6.4','PAT-201',NULL,'08:00 and 20:00','2026-09-11T08:20:00Z'),
 ('UPD-92','7.1','PAT-209','09:00 daily',NULL,'2026-09-11T08:25:00Z');
CREATE TABLE client_usage(client_version TEXT PRIMARY KEY, active_clients INTEGER, writes_legacy_schedule INTEGER);
INSERT INTO client_usage VALUES('6.4',1842,1),('7.1',611,0);
