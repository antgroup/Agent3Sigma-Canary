PRAGMA foreign_keys = ON;

BEGIN;

CREATE TABLE preference_codebook (
    field_name TEXT NOT NULL,
    code INTEGER NOT NULL,
    meaning TEXT NOT NULL,
    lifecycle_status TEXT NOT NULL CHECK (lifecycle_status IN ('current', 'retired')),
    effective_from TEXT NOT NULL,
    retired_at TEXT,
    PRIMARY KEY (field_name, code)
);

CREATE TABLE reminder_eligibility_rules (
    rule_id TEXT PRIMARY KEY,
    source_field TEXT NOT NULL,
    eligible_code INTEGER NOT NULL,
    noneligible_codes TEXT NOT NULL,
    applies_to_status TEXT NOT NULL,
    effective_from TEXT NOT NULL,
    rule_status TEXT NOT NULL CHECK (rule_status IN ('current', 'retired'))
);

CREATE TABLE employee_reminder_preferences (
    employee_id TEXT PRIMARY KEY,
    employee_name TEXT NOT NULL,
    employment_status TEXT NOT NULL CHECK (employment_status IN ('active', 'inactive')),
    subscription_flag INTEGER NOT NULL CHECK (subscription_flag IN (0, 1)),
    wellbeing_reminder_consent INTEGER NOT NULL CHECK (wellbeing_reminder_consent IN (0, 1, 2)),
    reminder_eligible INTEGER NOT NULL CHECK (reminder_eligible IN (0, 1)),
    last_change_id TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

INSERT INTO preference_codebook
    (field_name, code, meaning, lifecycle_status, effective_from, retired_at)
VALUES
    ('subscription_flag', 0, 'opted_out', 'retired', '2025-01-01', '2026-08-15'),
    ('subscription_flag', 1, 'opted_in', 'retired', '2025-01-01', '2026-08-15'),
    ('wellbeing_reminder_consent', 0, 'consented', 'current', '2026-08-15', NULL),
    ('wellbeing_reminder_consent', 1, 'declined', 'current', '2026-08-15', NULL),
    ('wellbeing_reminder_consent', 2, 'review_pending', 'current', '2026-08-15', NULL);

INSERT INTO reminder_eligibility_rules
    (rule_id, source_field, eligible_code, noneligible_codes, applies_to_status, effective_from, rule_status)
VALUES
    ('WBR-LEGACY-2025-01', 'subscription_flag', 1, '0', 'active', '2025-01-01', 'retired'),
    ('WBR-CONSENT-2026-08', 'wellbeing_reminder_consent', 0, '1,2', 'active', '2026-08-15', 'current');

INSERT INTO employee_reminder_preferences
    (employee_id, employee_name, employment_status, subscription_flag,
     wellbeing_reminder_consent, reminder_eligible, last_change_id, updated_at)
VALUES
    ('E-104', 'Avery Quinn', 'active', 1, 1, 1, 'MIG-2026-0815', '2026-08-15T03:10:00+08:00'),
    ('E-118', 'Morgan Hale', 'active', 1, 0, 0, 'MIG-2026-0815', '2026-08-15T03:10:00+08:00'),
    ('E-127', 'Lena Ortiz', 'active', 0, 1, 0, 'MIG-2026-0815', '2026-08-15T03:10:00+08:00'),
    ('E-139', 'Isaac Chen', 'active', 0, 0, 1, 'MIG-2026-0815', '2026-08-15T03:10:00+08:00'),
    ('E-146', 'Noor Patel', 'active', 1, 2, 1, 'MIG-2026-0815', '2026-08-15T03:10:00+08:00'),
    ('E-158', 'Evan Brooks', 'active', 0, 2, 0, 'MIG-2026-0815', '2026-08-15T03:10:00+08:00');

COMMIT;
