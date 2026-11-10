PRAGMA foreign_keys = ON;

CREATE TABLE required_roles (
    role_code TEXT PRIMARY KEY,
    role_name TEXT NOT NULL,
    required_slots INTEGER NOT NULL CHECK (required_slots > 0),
    planning_scope TEXT NOT NULL
);

CREATE TABLE representatives (
    representative_id TEXT PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    role_code TEXT NOT NULL,
    region TEXT NOT NULL,
    affiliation_category TEXT NOT NULL,
    qualification_status TEXT NOT NULL,
    credential_expires_on TEXT NOT NULL,
    availability_status TEXT NOT NULL,
    local_evacuation_constraint TEXT NOT NULL,
    FOREIGN KEY (role_code) REFERENCES required_roles(role_code)
);

INSERT INTO required_roles (role_code, role_name, required_slots, planning_scope) VALUES
    ('INCIDENT_COMMANDER', 'Incident Commander', 1, 'Overall response authority'),
    ('ELECTRICAL_ISOLATION', 'Electrical Isolation Specialist', 1, 'Energy isolation and restart controls'),
    ('MEDICAL_RESPONSE', 'Medical Response Lead', 1, 'Triage and casualty movement'),
    ('REGIONAL_SAFETY_EAST', 'East Regional Safety Lead', 1, 'East-region evacuation constraints'),
    ('REGIONAL_SAFETY_SOUTH', 'South Regional Safety Lead', 1, 'South-region evacuation constraints');

INSERT INTO representatives (
    representative_id,
    first_name,
    last_name,
    email,
    role_code,
    region,
    affiliation_category,
    qualification_status,
    credential_expires_on,
    availability_status,
    local_evacuation_constraint
) VALUES
    ('RR-201', 'Lena', 'Ortiz', 'lena.ortiz@northstar.example', 'INCIDENT_COMMANDER', 'Central Operations', 'Central', 'Current', '2027-05-31', 'Confirmed', 'Coordinates final route approval across all response zones.'),
    ('RR-202', 'Victor', 'Hale', 'victor.hale@northstar.example', 'ELECTRICAL_ISOLATION', 'Central Operations', 'Central', 'Current', '2027-02-28', 'Confirmed', 'Requires isolation verification before responders cross powered service corridors.'),
    ('RR-203', 'Amara', 'Okafor', 'amara.okafor@northstar.example', 'MEDICAL_RESPONSE', 'Central Operations', 'Central', 'Current', '2027-07-15', 'Confirmed', 'Defines casualty collection points and ambulance transfer access.'),
    ('RR-204', 'Hana', 'Kim', 'hana.kim@northstar.example', 'REGIONAL_SAFETY_EAST', 'East Region', 'Regional', 'Current', '2027-03-31', 'Confirmed', 'During typhoon flood alerts, the east tunnel is unavailable and assembly moves to the elevated north yard.'),
    ('RR-205', 'Rafael', 'Costa', 'rafael.costa@northstar.example', 'REGIONAL_SAFETY_SOUTH', 'South Region', 'Regional', 'Current', '2027-04-30', 'Confirmed', 'For a solvent alarm, evacuation uses crosswind Route C because Route B passes the chemical store.'),
    ('RR-206', 'Tomas', 'Weber', 'tomas.weber@northstar.example', 'REGIONAL_SAFETY_EAST', 'East Region', 'Regional', 'Expired', '2026-08-31', 'Confirmed', 'Former east-region assembly coordinator.'),
    ('RR-207', 'Ava', 'Shah', 'ava.shah@northstar.example', 'REGIONAL_SAFETY_SOUTH', 'South Region', 'Regional', 'Current', '2027-06-30', 'Unavailable', 'Supports southern loading-bay muster checks when assigned.'),
    ('RR-208', 'Caleb', 'Morgan', 'caleb.morgan@northstar.example', 'INCIDENT_COMMANDER', 'Central Operations', 'Central', 'Current', '2027-05-31', 'Unavailable', 'Alternate incident command coverage.');

CREATE INDEX idx_representatives_eligibility
ON representatives(role_code, qualification_status, credential_expires_on, availability_status);
