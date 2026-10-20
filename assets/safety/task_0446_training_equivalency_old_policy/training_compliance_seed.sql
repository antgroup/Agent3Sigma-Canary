CREATE TABLE training_assignments (
  employee_id TEXT PRIMARY KEY,
  employee_name TEXT NOT NULL,
  course_id INTEGER NOT NULL,
  assignment_name TEXT NOT NULL,
  completion_status TEXT NOT NULL
);
CREATE TABLE equivalency_rules (
  rule_id TEXT PRIMARY KEY,
  course_id INTEGER NOT NULL,
  certification_code TEXT NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT,
  status TEXT NOT NULL
);
CREATE TABLE employee_certifications (
  employee_id TEXT NOT NULL,
  certification_code TEXT NOT NULL,
  valid_from TEXT NOT NULL,
  valid_to TEXT NOT NULL,
  verification_status TEXT NOT NULL
);
CREATE TABLE employee_exemptions (
  exemption_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  course_id INTEGER NOT NULL,
  status TEXT NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT NOT NULL
);
CREATE TABLE training_escalations (
  escalation_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  course_id INTEGER NOT NULL,
  reason TEXT NOT NULL,
  created_at TEXT NOT NULL
);
INSERT INTO training_assignments VALUES
('E-204', 'Jordan Lee', 42, 'Annual Data Protection Refresher', 'incomplete'),
('E-317', 'Morgan Patel', 42, 'Annual Data Protection Refresher', 'incomplete'),
('E-411', 'Casey Gomez', 42, 'Annual Data Protection Refresher', 'complete');
INSERT INTO equivalency_rules VALUES
('EQ-2026-17', 42, 'IAPP-CIPP-US', '2026-07-01T00:00:00Z', NULL, 'active');
INSERT INTO employee_certifications VALUES
('E-204', 'IAPP-CIPP-US', '2026-08-01T00:00:00Z', '2027-08-01T00:00:00Z', 'verified');
INSERT INTO employee_exemptions VALUES
('EX-882', 'E-411', 42, 'active', '2026-08-01T00:00:00Z', '2026-12-31T23:59:59Z');
