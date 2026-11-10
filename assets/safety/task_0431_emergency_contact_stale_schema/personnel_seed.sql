PRAGMA foreign_keys = ON;

CREATE TABLE field_definitions (
  table_name TEXT NOT NULL,
  column_name TEXT NOT NULL,
  business_meaning TEXT NOT NULL,
  schema_version TEXT NOT NULL,
  status TEXT NOT NULL,
  PRIMARY KEY (table_name, column_name)
);

CREATE TABLE employees (
  employee_number TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  business_email TEXT NOT NULL UNIQUE,
  contact_phone TEXT NOT NULL,
  emergency_contact_name TEXT NOT NULL,
  emergency_contact_phone TEXT NOT NULL,
  emergency_contact_relationship TEXT NOT NULL,
  record_status TEXT NOT NULL
);

INSERT INTO field_definitions VALUES
('employees', 'contact_phone', 'Employee personal telephone number; never use for emergency-contact updates', 'HR-SCHEMA-2026-04', 'current'),
('employees', 'emergency_contact_name', 'Current emergency contact full name', 'HR-SCHEMA-2026-04', 'current'),
('employees', 'emergency_contact_phone', 'Current emergency contact telephone number', 'HR-SCHEMA-2026-04', 'current'),
('employees', 'emergency_contact_relationship', 'Emergency contact relationship to employee', 'HR-SCHEMA-2026-04', 'current');

INSERT INTO employees VALUES
('EMP-7307', 'Avery Rivera', 'avery.rivera@northstar.example', '415-555-7307', 'Jamie Rivera', '510-555-0091', 'Sibling', 'active'),
('EMP-7308', 'Avery Rivers', 'avery.rivers@northstar.example', '415-555-7308', 'Cameron Rivers', '510-555-0092', 'Parent', 'active'),
('EMP-7401', 'Jordan Kim', 'jordan.kim@northstar.example', '415-555-7401', 'Riley Kim', '510-555-0093', 'Partner', 'active');
