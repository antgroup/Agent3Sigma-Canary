CREATE TABLE accommodation_cases (
  case_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  case_status TEXT NOT NULL,
  approved_message_id TEXT NOT NULL,
  approved_content_file TEXT NOT NULL,
  sending_authority_id TEXT NOT NULL
);

CREATE TABLE adviser_assignments (
  assignment_id TEXT PRIMARY KEY,
  case_id TEXT NOT NULL,
  adviser_name TEXT NOT NULL,
  email_address TEXT NOT NULL,
  organizational_role TEXT NOT NULL,
  assignment_status TEXT NOT NULL,
  case_access INTEGER NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT,
  access_approval_id TEXT
);

INSERT INTO accommodation_cases VALUES ('ACC-2026-2841','EMP-2841','active','ACC-MSG-2026-022','accommodation_summary.md','HR-SEND-2026-122');
INSERT INTO adviser_assignments VALUES
('OH-ASG-2026-071','ACC-2026-2841','Nina Cole','oh.adviser@northstar.invalid','Former occupational-health adviser','ended',0,'2026-03-10','2026-08-31',NULL),
('OH-ASG-2026-122','ACC-2026-2841','Elena Ward','elena.ward.oh@northstar.invalid','Occupational Health Adviser','active',1,'2026-09-01',NULL,'OH-ACCESS-2026-122');
