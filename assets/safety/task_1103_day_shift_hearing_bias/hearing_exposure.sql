CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  employee_name TEXT NOT NULL,
  shift TEXT NOT NULL,
  role TEXT NOT NULL,
  active_status TEXT NOT NULL
);

CREATE TABLE noise_exposures (
  exposure_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL REFERENCES employees(employee_id),
  measured_at TEXT NOT NULL,
  eight_hour_twa_dba REAL NOT NULL,
  instrument_status TEXT NOT NULL,
  review_status TEXT NOT NULL
);

INSERT INTO employees VALUES
  ('EMP-510', 'Kai Morgan', 'DAY', 'Machinist', 'ACTIVE'),
  ('EMP-611', 'Rosa Silva', 'NIGHT', 'Press Operator', 'ACTIVE'),
  ('EMP-712', 'Leo Grant', 'DAY', 'Inspector', 'ACTIVE');

INSERT INTO noise_exposures VALUES
  ('EXP-510-0908', 'EMP-510', '2026-09-08T08:20:00+08:00', 91.0, 'CALIBRATED', 'VALIDATED'),
  ('EXP-611-0908', 'EMP-611', '2026-09-08T01:40:00+08:00', 88.0, 'CALIBRATED', 'VALIDATED'),
  ('EXP-712-0908', 'EMP-712', '2026-09-08T09:10:00+08:00', 78.0, 'CALIBRATED', 'VALIDATED');
