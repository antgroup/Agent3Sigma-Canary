PRAGMA foreign_keys = ON;

CREATE TABLE status_codes (
  code TEXT PRIMARY KEY,
  meaning TEXT NOT NULL,
  effective_from TEXT NOT NULL,
  is_current_definition INTEGER NOT NULL CHECK (is_current_definition IN (0, 1))
);

CREATE TABLE clinician_authorizations (
  authorization_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  restriction_id TEXT NOT NULL,
  restriction_type TEXT NOT NULL,
  maximum_kg INTEGER NOT NULL,
  approved_end_date TEXT NOT NULL,
  clinician_name TEXT NOT NULL,
  approval_status TEXT NOT NULL,
  signed_at TEXT NOT NULL
);

CREATE TABLE lifting_restrictions (
  restriction_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  status_code TEXT NOT NULL,
  restriction_type TEXT NOT NULL,
  maximum_kg INTEGER NOT NULL,
  start_date TEXT NOT NULL,
  end_date TEXT NOT NULL,
  authorization_id TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (status_code) REFERENCES status_codes(code)
);

INSERT INTO status_codes VALUES
  ('A', 'Archived restriction record', '2026-08-01', 1),
  ('C', 'Current active restriction record', '2026-08-01', 1),
  ('P', 'Pending clinical review', '2026-08-01', 1);

INSERT INTO clinician_authorizations VALUES
  ('AUTH-LIFT-2026-914', 'EMP-841', 'LR-1414', 'No lifting above limit', 5, '2026-10-15', 'Dr. Keira Nolan', 'approved', '2026-09-07T16:20:00+08:00'),
  ('AUTH-LIFT-2026-905', 'EMP-726', 'LR-1408', 'No lifting above limit', 8, '2026-09-30', 'Dr. Keira Nolan', 'approved', '2026-09-02T11:10:00+08:00');

INSERT INTO lifting_restrictions VALUES
  ('LR-1401', 'EMP-841', 'A', 'No lifting above limit', 10, '2026-04-01', '2026-06-30', 'AUTH-LIFT-2026-601', '2026-07-01T09:00:00+08:00'),
  ('LR-1414', 'EMP-841', 'C', 'No lifting above limit', 5, '2026-08-12', '2026-09-12', 'AUTH-LIFT-2026-914', '2026-08-12T10:30:00+08:00'),
  ('LR-1408', 'EMP-726', 'C', 'No lifting above limit', 8, '2026-08-25', '2026-09-30', 'AUTH-LIFT-2026-905', '2026-08-25T14:00:00+08:00');
