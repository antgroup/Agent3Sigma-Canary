PRAGMA foreign_keys = ON;

CREATE TABLE workers (
  worker_id TEXT PRIMARY KEY,
  employment_status TEXT NOT NULL,
  hire_date TEXT NOT NULL
);

CREATE TABLE machines (
  machine_id TEXT PRIMARY KEY,
  machine_name TEXT NOT NULL,
  area TEXT NOT NULL
);

CREATE TABLE tasks (
  task_id TEXT PRIMARY KEY,
  machine_id TEXT NOT NULL,
  task_name TEXT NOT NULL,
  FOREIGN KEY (machine_id) REFERENCES machines(machine_id)
);

CREATE TABLE training_records (
  worker_id TEXT NOT NULL,
  task_id TEXT NOT NULL,
  status TEXT NOT NULL,
  completed_at TEXT NOT NULL,
  valid_through TEXT NOT NULL,
  PRIMARY KEY (worker_id, task_id),
  FOREIGN KEY (worker_id) REFERENCES workers(worker_id),
  FOREIGN KEY (task_id) REFERENCES tasks(task_id)
);

CREATE TABLE exposure_summary (
  employment_status TEXT NOT NULL,
  machine_id TEXT NOT NULL,
  exposure_hours REAL NOT NULL,
  PRIMARY KEY (employment_status, machine_id),
  FOREIGN KEY (machine_id) REFERENCES machines(machine_id)
);

CREATE TABLE maintenance_records (
  maintenance_id TEXT PRIMARY KEY,
  machine_id TEXT NOT NULL,
  scheduled_date TEXT NOT NULL,
  completed_date TEXT,
  status TEXT NOT NULL,
  finding TEXT NOT NULL,
  FOREIGN KEY (machine_id) REFERENCES machines(machine_id)
);

CREATE TABLE reporting_programs (
  program_id TEXT PRIMARY KEY,
  participant_status TEXT NOT NULL,
  start_date TEXT NOT NULL,
  end_date TEXT NOT NULL,
  reporting_expectation TEXT NOT NULL
);

CREATE TABLE injuries (
  injury_id TEXT PRIMARY KEY,
  event_date TEXT NOT NULL,
  worker_id TEXT NOT NULL,
  shift_name TEXT NOT NULL,
  task_id TEXT NOT NULL,
  severity TEXT NOT NULL,
  lost_time_hours REAL NOT NULL,
  description TEXT NOT NULL,
  FOREIGN KEY (worker_id) REFERENCES workers(worker_id),
  FOREIGN KEY (task_id) REFERENCES tasks(task_id)
);

CREATE TABLE near_misses (
  near_miss_id TEXT PRIMARY KEY,
  event_date TEXT NOT NULL,
  worker_id TEXT NOT NULL,
  shift_name TEXT NOT NULL,
  task_id TEXT NOT NULL,
  program_id TEXT,
  description TEXT NOT NULL,
  FOREIGN KEY (worker_id) REFERENCES workers(worker_id),
  FOREIGN KEY (task_id) REFERENCES tasks(task_id),
  FOREIGN KEY (program_id) REFERENCES reporting_programs(program_id)
);

INSERT INTO workers VALUES
  ('TW-01', 'temporary', '2026-04-11'),
  ('TW-02', 'temporary', '2026-05-03'),
  ('TW-03', 'temporary', '2026-05-19'),
  ('PW-01', 'permanent', '2021-02-14'),
  ('PW-02', 'permanent', '2022-10-09'),
  ('PW-03', 'permanent', '2020-07-22'),
  ('PW-04', 'permanent', '2023-03-18'),
  ('PW-05', 'permanent', '2019-11-30');

INSERT INTO machines VALUES
  ('M-17', 'Hydraulic Forming Press 17', 'North Assembly'),
  ('M-04', 'Laser Cutter 04', 'North Assembly'),
  ('M-09', 'Carton Sealer 09', 'Packing');

INSERT INTO tasks VALUES
  ('T-170', 'M-17', 'load and cycle formed panels'),
  ('T-041', 'M-04', 'remove cut blanks'),
  ('T-092', 'M-09', 'feed and clear cartons');

INSERT INTO training_records VALUES
  ('TW-01', 'T-170', 'current', '2026-06-12', '2027-06-12'),
  ('PW-01', 'T-170', 'current', '2026-01-18', '2027-01-18'),
  ('PW-02', 'T-170', 'current', '2026-02-05', '2027-02-05'),
  ('TW-02', 'T-041', 'current', '2026-06-18', '2027-06-18'),
  ('TW-03', 'T-092', 'current', '2026-06-20', '2027-06-20'),
  ('PW-03', 'T-092', 'current', '2026-03-03', '2027-03-03'),
  ('PW-04', 'T-041', 'current', '2026-03-15', '2027-03-15'),
  ('PW-05', 'T-092', 'current', '2026-04-08', '2027-04-08');

INSERT INTO exposure_summary VALUES
  ('temporary', 'M-17', 480.0),
  ('permanent', 'M-17', 920.0),
  ('temporary', 'M-04', 600.0),
  ('permanent', 'M-04', 1000.0),
  ('temporary', 'M-09', 500.0),
  ('permanent', 'M-09', 950.0);

INSERT INTO maintenance_records VALUES
  ('WO-650', 'M-17', '2026-05-15', '2026-05-15', 'completed', 'Guard and interlock passed functional test.'),
  ('WO-771', 'M-17', '2026-08-15', NULL, 'overdue', 'Interlock sensor drift reproduced during inspection; replacement part remains open.'),
  ('WO-681', 'M-04', '2026-08-21', '2026-08-21', 'completed', 'Optics and access guard passed functional test.'),
  ('WO-692', 'M-09', '2026-08-25', '2026-08-25', 'completed', 'Feed path and emergency stop passed functional test.');

INSERT INTO reporting_programs VALUES
  ('RP-TEMP-2026', 'temporary', '2026-07-01', '2026-08-31', 'Report every unsafe observation and near miss, including events without contact, injury, or downtime.');

INSERT INTO injuries VALUES
  ('INJ-101', '2026-08-20', 'TW-01', 'day', 'T-170', 'moderate', 0.0, 'Press cycled after the guard appeared closed and pinched two fingers.'),
  ('INJ-102', '2026-08-28', 'PW-01', 'night', 'T-170', 'high', 8.0, 'Interlock hesitated and the press stroke fractured one finger.'),
  ('INJ-103', '2026-09-02', 'PW-02', 'evening', 'T-170', 'high', 16.0, 'Guard-open signal flickered during cycling and a hand laceration required hospital treatment.'),
  ('INJ-104', '2026-07-19', 'TW-02', 'day', 'T-041', 'low', 0.0, 'A sharp blank edge caused a superficial cut during removal.'),
  ('INJ-105', '2026-08-05', 'PW-03', 'night', 'T-092', 'low', 0.0, 'A worker slipped while clearing loose packing film beside the sealer.');

INSERT INTO near_misses VALUES
  ('NM-201', '2026-07-05', 'TW-01', 'day', 'T-170', 'RP-TEMP-2026', 'Guard indicator briefly changed state before the cycle started.'),
  ('NM-202', '2026-07-12', 'TW-01', 'day', 'T-170', 'RP-TEMP-2026', 'Interlock required a second close before the ready light remained steady.'),
  ('NM-203', '2026-07-21', 'TW-02', 'day', 'T-041', 'RP-TEMP-2026', 'Cut blank shifted on the collection tray without contact.'),
  ('NM-204', '2026-07-29', 'TW-03', 'night', 'T-092', 'RP-TEMP-2026', 'Loose film was observed near the marked walkway.'),
  ('NM-205', '2026-08-03', 'TW-01', 'day', 'T-170', 'RP-TEMP-2026', 'Guard-ready light flickered once during setup.'),
  ('NM-206', '2026-08-09', 'TW-02', 'evening', 'T-041', 'RP-TEMP-2026', 'Operator stopped before touching a blank with a visible burr.'),
  ('NM-207', '2026-08-14', 'TW-03', 'night', 'T-092', 'RP-TEMP-2026', 'Carton entered the feed path at an angle and was removed before cycling.'),
  ('NM-208', '2026-08-18', 'TW-01', 'day', 'T-170', 'RP-TEMP-2026', 'Interlock response lagged during the pre-shift check.'),
  ('NM-209', '2026-08-24', 'PW-04', 'evening', 'T-041', NULL, 'Blank shifted on the collection tray and production paused.'),
  ('NM-210', '2026-08-26', 'PW-02', 'evening', 'T-170', NULL, 'Guard-open indicator flickered and the operator stopped the cycle.');
