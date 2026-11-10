CREATE TABLE employees (
  employee_number INTEGER PRIMARY KEY,
  employee_id TEXT NOT NULL UNIQUE,
  employee_name TEXT NOT NULL,
  department TEXT NOT NULL
);
CREATE TABLE badge_events (
  event_id TEXT PRIMARY KEY,
  employee_number INTEGER NOT NULL,
  event_time TEXT NOT NULL,
  event_type TEXT NOT NULL CHECK (event_type IN ('IN','OUT')),
  reader_status TEXT NOT NULL,
  FOREIGN KEY (employee_number) REFERENCES employees(employee_number)
);
CREATE TABLE payroll_attendance (
  ledger_id TEXT PRIMARY KEY,
  employee_number INTEGER NOT NULL,
  work_date TEXT NOT NULL,
  first_in TEXT,
  last_out TEXT,
  status TEXT NOT NULL,
  source TEXT NOT NULL,
  FOREIGN KEY (employee_number) REFERENCES employees(employee_number)
);
INSERT INTO employees VALUES
  (4,'E-7314','Alicia Moreno','Fulfillment'),
  (5,'E-7428','Ben Ito','Fulfillment'),
  (6,'E-7551','Chloe Mensah','Customer Operations');
INSERT INTO badge_events VALUES
  ('BG-0901-A',4,'2026-09-01T08:02:00+08:00','IN','online'),
  ('BG-0901-B',4,'2026-09-01T17:06:00+08:00','OUT','online'),
  ('BG-0902-A',5,'2026-09-02T08:11:00+08:00','IN','online'),
  ('BG-0903-A',6,'2026-09-03T17:20:00+08:00','OUT','recovered_after_outage');
INSERT INTO payroll_attendance VALUES
  ('LD-0901-1',4,'2026-09-01','2026-09-01T08:02:00+08:00','2026-09-01T17:06:00+08:00','complete','badge'),
  ('LD-0902-2',5,'2026-09-02','2026-09-02T08:11:00+08:00',NULL,'missing_out','badge'),
  ('LD-0903-3',6,'2026-09-03',NULL,'2026-09-03T17:20:00+08:00','missing_in','badge'),
  ('LD-0904-1',4,'2026-09-04','2026-09-04T08:00:00+08:00','2026-09-04T17:00:00+08:00','manual_pending_review','supervisor_sheet');
