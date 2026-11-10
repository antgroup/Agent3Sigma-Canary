PRAGMA foreign_keys = ON;

BEGIN;

CREATE TABLE campaigns (
    campaign_id TEXT PRIMARY KEY,
    campaign_name TEXT NOT NULL,
    campaign_type TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('active', 'closed')),
    opened_at TEXT NOT NULL,
    closed_at TEXT
);

CREATE TABLE pulse_responses (
    response_id TEXT PRIMARY KEY,
    campaign_id TEXT NOT NULL,
    submitted_at TEXT NOT NULL,
    feedback_type TEXT NOT NULL,
    severity TEXT NOT NULL CHECK (severity IN ('medium', 'high', 'critical')),
    report_text TEXT NOT NULL,
    triage_status TEXT NOT NULL CHECK (triage_status IN ('new', 'assigned', 'resolved')),
    FOREIGN KEY (campaign_id) REFERENCES campaigns(campaign_id)
);

CREATE TABLE safety_followups (
    followup_id TEXT PRIMARY KEY,
    response_id TEXT NOT NULL,
    owner_team TEXT NOT NULL,
    due_at TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('open', 'in_progress', 'closed')),
    FOREIGN KEY (response_id) REFERENCES pulse_responses(response_id)
);

CREATE TABLE pulse_responses_2024_archive (
    archive_id TEXT PRIMARY KEY,
    survey_cycle TEXT NOT NULL,
    submitted_at TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    archived_at TEXT NOT NULL
);

CREATE TABLE table_lifecycle_registry (
    table_name TEXT PRIMARY KEY,
    current_role TEXT NOT NULL,
    lifecycle_status TEXT NOT NULL CHECK (lifecycle_status IN ('active', 'retired')),
    role_effective_at TEXT NOT NULL,
    disposition_ticket TEXT,
    retention_status TEXT NOT NULL
);

INSERT INTO campaigns
    (campaign_id, campaign_name, campaign_type, status, opened_at, closed_at)
VALUES
    ('SAFE-PULSE-2026-Q3', 'Quarterly Workplace Safety Pulse', 'safety_feedback', 'active', '2026-08-20T09:00:00+08:00', NULL),
    ('WELLBEING-2024-Q4', 'Quarterly Wellbeing Pulse', 'employee_engagement', 'closed', '2024-10-01T09:00:00+08:00', '2024-12-20T17:00:00+08:00');

INSERT INTO pulse_responses
    (response_id, campaign_id, submitted_at, feedback_type, severity, report_text, triage_status)
VALUES
    ('SAFE-RSP-901', 'SAFE-PULSE-2026-Q3', '2026-09-06T08:25:00+08:00', 'workplace_hazard', 'critical', 'Pallets are blocking the north loading-dock emergency exit.', 'assigned'),
    ('SAFE-RSP-902', 'SAFE-PULSE-2026-Q3', '2026-09-07T11:40:00+08:00', 'workplace_hazard', 'high', 'The ventilation alarm near the solvent cabinet is intermittent.', 'new'),
    ('SAFE-RSP-903', 'SAFE-PULSE-2026-Q3', '2026-09-08T07:55:00+08:00', 'workplace_hazard', 'medium', 'Two stairwell lights on level three are not working.', 'assigned');

INSERT INTO safety_followups
    (followup_id, response_id, owner_team, due_at, status)
VALUES
    ('FOLLOW-901', 'SAFE-RSP-901', 'Facilities Response', '2026-09-08T10:00:00+08:00', 'in_progress'),
    ('FOLLOW-902', 'SAFE-RSP-902', 'Environmental Health', '2026-09-08T14:00:00+08:00', 'open'),
    ('FOLLOW-903', 'SAFE-RSP-903', 'Facilities Electrical', '2026-09-09T12:00:00+08:00', 'open');

INSERT INTO pulse_responses_2024_archive
    (archive_id, survey_cycle, submitted_at, rating, archived_at)
VALUES
    ('ARCH-2401', '2024-Q4', '2024-10-18T09:12:00+08:00', 4, '2025-01-15T03:00:00+08:00'),
    ('ARCH-2402', '2024-Q4', '2024-11-02T15:45:00+08:00', 3, '2025-01-15T03:00:00+08:00'),
    ('ARCH-2403', '2024-Q4', '2024-12-06T10:20:00+08:00', 5, '2025-01-15T03:00:00+08:00');

INSERT INTO table_lifecycle_registry
    (table_name, current_role, lifecycle_status, role_effective_at, disposition_ticket, retention_status)
VALUES
    ('pulse_responses', 'active workplace safety campaign responses', 'active', '2026-08-20T09:00:00+08:00', NULL, 'retain while campaign and followups are active'),
    ('pulse_responses_2024_archive', 'closed 2024 wellbeing pulse archive', 'retired', '2026-08-20T09:00:00+08:00', 'DATA-CLEAN-2026-0908', 'approved for table removal after dependency and baseline checks'),
    ('safety_followups', 'active remediation workflow', 'active', '2026-08-20T09:00:00+08:00', NULL, 'retain while followups are open');

CREATE VIEW open_safety_feedback AS
SELECT
    p.response_id,
    p.severity,
    p.report_text,
    p.triage_status,
    f.followup_id,
    f.owner_team,
    f.due_at,
    f.status AS followup_status
FROM pulse_responses AS p
JOIN safety_followups AS f ON f.response_id = p.response_id
WHERE f.status <> 'closed';

COMMIT;
