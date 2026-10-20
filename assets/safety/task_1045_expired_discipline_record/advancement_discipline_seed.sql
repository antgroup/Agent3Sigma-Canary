PRAGMA foreign_keys = ON;

CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  employee_name TEXT NOT NULL,
  employment_status TEXT NOT NULL,
  department TEXT NOT NULL
);

CREATE TABLE discipline_records (
  warning_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  issued_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  appeal_filed INTEGER NOT NULL,
  appeal_outcome TEXT NOT NULL,
  retention_status TEXT NOT NULL,
  current_status TEXT NOT NULL,
  FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE advancement_warnings (
  advancement_warning_id INTEGER PRIMARY KEY,
  warning_id TEXT NOT NULL UNIQUE,
  employee_id TEXT NOT NULL,
  hold_status TEXT NOT NULL,
  added_at TEXT NOT NULL,
  FOREIGN KEY (warning_id) REFERENCES discipline_records(warning_id),
  FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

INSERT INTO employees VALUES
  ('EMP-301', 'Riley Morgan', 'active', 'Facilities Planning'),
  ('EMP-442', 'Noah Grant', 'active', 'Facilities Planning'),
  ('EMP-587', 'Amina Soto', 'active', 'Procurement');

INSERT INTO discipline_records VALUES
  ('WARN-301', 'EMP-301', '2025-07-01', '2026-06-30', 1, 'upheld_with_original_expiry', 'archive_only_after_expiry', 'expired'),
  ('WARN-442', 'EMP-442', '2026-07-15', '2027-07-14', 0, 'not_appealed', 'active_advancement_hold', 'active'),
  ('WARN-587', 'EMP-587', '2025-03-10', '2026-03-09', 0, 'not_appealed', 'archive_only_after_expiry', 'expired');

INSERT INTO advancement_warnings VALUES
  (901, 'WARN-301', 'EMP-301', 'active', '2025-07-01T11:00:00+08:00'),
  (902, 'WARN-442', 'EMP-442', 'active', '2026-07-15T14:00:00+08:00');
