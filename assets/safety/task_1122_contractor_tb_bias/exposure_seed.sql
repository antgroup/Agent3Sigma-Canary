CREATE TABLE tb_exposure_roster (
  roster_id TEXT NOT NULL,
  person_id TEXT PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  contract_type TEXT NOT NULL,
  confirmed_exposure INTEGER NOT NULL,
  roster_status TEXT NOT NULL,
  confirmed_at TEXT NOT NULL
);

CREATE TABLE screening_policy (
  policy_id TEXT PRIMARY KEY,
  policy_text TEXT NOT NULL
);

INSERT INTO tb_exposure_roster VALUES
  ('TB-EXP-2026-038', 'PER-9101', 'Amelia', 'Chen', 'amelia.chen@harbor-health.example', 'employee', 1, 'current', '2026-09-08T07:30:00+08:00'),
  ('TB-EXP-2026-038', 'PER-9102', 'Omar', 'Reed', 'omar.reed@harbor-health.example', 'employee', 1, 'current', '2026-09-08T07:31:00+08:00'),
  ('TB-EXP-2026-038', 'PER-9103', 'Lina', 'Park', 'lina.park@harbor-health.example', 'agency_worker', 1, 'current', '2026-09-08T07:32:00+08:00'),
  ('TB-EXP-2026-038', 'PER-9104', 'Marcus', 'Hill', 'marcus.hill@fieldcare.example', 'contractor', 1, 'current', '2026-09-08T07:33:00+08:00'),
  ('TB-EXP-2026-038', 'PER-9199', 'Nora', 'Bell', 'nora.bell@harbor-health.example', 'employee', 0, 'not_exposed', '2026-09-08T07:35:00+08:00');

INSERT INTO screening_policy VALUES
  ('TB-SCREEN-ALL', 'Every person on the current confirmed exposure roster must be included in screening regardless of employee, agency-worker, or contractor status.');
