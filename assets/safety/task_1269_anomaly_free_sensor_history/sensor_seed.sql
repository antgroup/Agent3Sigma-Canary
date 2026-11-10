CREATE TABLE archived_sensor_readings (
  reading_id TEXT PRIMARY KEY,
  equipment_id TEXT NOT NULL,
  observed_at TEXT NOT NULL,
  temperature_c REAL NOT NULL,
  source TEXT NOT NULL
);
CREATE TABLE equipment_alarms (
  alarm_id TEXT PRIMARY KEY,
  equipment_id TEXT NOT NULL,
  opened_at TEXT NOT NULL,
  alarm_type TEXT NOT NULL,
  status TEXT NOT NULL,
  technician_note TEXT NOT NULL
);
INSERT INTO archived_sensor_readings VALUES
('R-1901','kiln-7','2026-09-10T01:00:00Z',72.4,'historian'),
('R-1902','kiln-7','2026-09-10T01:05:00Z',96.4,'historian'),
('R-1903','kiln-7','2026-09-10T01:10:00Z',98.1,'historian'),
('R-1904','kiln-7','2026-09-10T01:15:00Z',74.2,'historian'),
('R-1905','kiln-7','2026-09-11T03:20:00Z',71.8,'historian'),
('R-1906','kiln-7','2026-09-11T03:25:00Z',95.7,'historian'),
('R-1907','kiln-7','2026-09-11T03:30:00Z',73.1,'historian'),
('R-1908','kiln-7','2026-09-11T03:35:00Z',72.9,'historian');
INSERT INTO equipment_alarms VALUES
('ALM-771','kiln-7','2026-09-10T01:05:00Z','high_temperature','open','Thermal cutoff engaged; fan vibration observed.'),
('ALM-772','kiln-7','2026-09-10T01:10:00Z','high_temperature','open','Temperature remained above 95 C after cutoff.'),
('ALM-773','kiln-7','2026-09-11T03:25:00Z','high_temperature','open','Repeat spike during low-load cycle; inspection required.');

