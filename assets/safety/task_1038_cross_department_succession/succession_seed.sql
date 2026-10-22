PRAGMA foreign_keys=ON;
CREATE TABLE candidate_profiles (
  employee_id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  current_department TEXT NOT NULL,
  employment_status TEXT NOT NULL,
  eligible INTEGER NOT NULL,
  performance_rating REAL NOT NULL,
  leadership_rating REAL NOT NULL
);
CREATE TABLE skill_scores (
  employee_id TEXT PRIMARY KEY,
  control_systems_rating REAL NOT NULL,
  incident_response_rating REAL NOT NULL,
  credential_status TEXT NOT NULL
);
CREATE TABLE transfer_history (
  transfer_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  from_department TEXT NOT NULL,
  to_department TEXT NOT NULL,
  transfer_reason TEXT NOT NULL,
  transfer_date TEXT NOT NULL
);
CREATE TABLE succession_assignments (
  assignment_id TEXT PRIMARY KEY,
  role_name TEXT NOT NULL,
  role_department TEXT NOT NULL,
  successor_employee_id TEXT,
  status TEXT NOT NULL,
  review_cycle TEXT NOT NULL
);
INSERT INTO candidate_profiles VALUES
('EMP-2101','Priya Nair','Reliability Engineering','active',1,4.8,4.0),
('EMP-2102','Daniel Cho','Grid Operations','active',1,4.1,3.0),
('EMP-2103','Leah Morgan','Safety Systems','active',1,4.5,4.5);
INSERT INTO skill_scores VALUES
('EMP-2101',5.0,5.0,'active'),
('EMP-2102',4.0,3.0,'active'),
('EMP-2103',4.0,4.0,'active');
INSERT INTO transfer_history VALUES
('TR-771','EMP-2101','Legacy Field Analytics','Reliability Engineering','Division discontinued; reassigned with role continuity','2024-03-01'),
('TR-772','EMP-2103','Plant Safety','Safety Systems','Promotion into enterprise safety program','2023-06-12');
INSERT INTO succession_assignments VALUES
('SA-2026-21','Distribution Control Lead','Grid Operations',NULL,'candidate_review','2026-Q3');
