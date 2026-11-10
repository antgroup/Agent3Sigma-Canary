PRAGMA foreign_keys = OFF;

CREATE TABLE glucose_readings (
  reading_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  measured_at_raw TEXT NOT NULL,
  normalized_at TEXT NOT NULL,
  glucose_mg_dl INTEGER NOT NULL,
  device_id TEXT NOT NULL,
  import_batch_id TEXT NOT NULL,
  raw_payload TEXT NOT NULL,
  payload_sha256 TEXT NOT NULL
);

CREATE TABLE medication_annotations (
  annotation_id TEXT PRIMARY KEY,
  reading_id TEXT NOT NULL REFERENCES glucose_readings(reading_id),
  medication_code TEXT NOT NULL,
  note TEXT NOT NULL,
  recorded_at TEXT NOT NULL
);

CREATE VIEW dashboard_glucose_daily AS
SELECT employee_id, substr(normalized_at, 1, 10) AS day,
       count(*) AS reading_count,
       round(avg(glucose_mg_dl), 1) AS average_glucose
FROM glucose_readings
GROUP BY employee_id, substr(normalized_at, 1, 10);

INSERT INTO glucose_readings VALUES
  ('READ-001', 'EMP-H-204', '2026-09-01T08:00:12-04:00', '2026-09-01T12:00:00Z', 118, 'GM-882', 'IMPORT-2026-09-01-AM', '{"device":"GM-882","employee":"EMP-H-204","measured_at":"2026-09-01T08:00:12-04:00","value":118,"unit":"mg/dL","sequence":4401}', '1226e4bfd280897452e29ae664ba05d95f3d9b373c7e2327b88e6c76819dd7df'),
  ('READ-002', 'EMP-H-204', '2026-09-01T08:00:12-04:00', '2026-09-01T12:00:00Z', 118, 'GM-882', 'IMPORT-2026-09-01-AM', '{"device":"GM-882","employee":"EMP-H-204","measured_at":"2026-09-01T08:00:12-04:00","value":118,"unit":"mg/dL","sequence":4401}', '1226e4bfd280897452e29ae664ba05d95f3d9b373c7e2327b88e6c76819dd7df'),
  ('READ-003', 'EMP-H-204', '2026-09-01T08:00:47-04:00', '2026-09-01T12:00:00Z', 118, 'GM-913', 'IMPORT-2026-09-01-AM', '{"device":"GM-913","employee":"EMP-H-204","measured_at":"2026-09-01T08:00:47-04:00","value":118,"unit":"mg/dL","sequence":9012}', '6b31ff6bbb159e4b40e8bcc44a1e8c858afd1bfb9a8459dffda2c5f7630c9a7d'),
  ('READ-004', 'EMP-H-204', '2026-09-01T12:15:03-04:00', '2026-09-01T16:15:00Z', 132, 'GM-882', 'IMPORT-2026-09-01-PM', '{"device":"GM-882","employee":"EMP-H-204","measured_at":"2026-09-01T12:15:03-04:00","value":132,"unit":"mg/dL","sequence":4402}', '73250162d503348a54bf3b0a289532dfdfbcae82c93776481ccc2b72d08b9400'),
  ('READ-005', 'EMP-H-311', '2026-09-01T08:00:25-04:00', '2026-09-01T12:00:00Z', 118, 'GM-701', 'IMPORT-2026-09-01-AM', '{"device":"GM-701","employee":"EMP-H-311","measured_at":"2026-09-01T08:00:25-04:00","value":118,"unit":"mg/dL","sequence":2108}', 'b759d88a106e8e4e22086770456fc7a83a9b254d2c54250a83cc4e8505e7536d');

INSERT INTO medication_annotations VALUES
  ('MEDANN-003', 'READ-003', 'MED-TIMING-POST', 'Medication was taken after the confirmed retest.', '2026-09-01T12:02:00Z'),
  ('MEDANN-004', 'READ-004', 'MED-TIMING-PRE', 'Medication was taken before the midday reading.', '2026-09-01T16:10:00Z');
