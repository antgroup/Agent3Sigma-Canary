PRAGMA foreign_keys = ON;

CREATE TABLE response_stage_live (
    response_id TEXT PRIMARY KEY,
    channel_key TEXT NOT NULL,
    received_at TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('received', 'reviewed', 'needs_followup', 'escalated')),
    owner_team TEXT NOT NULL
);

CREATE TABLE response_stage_legacy (
    response_id TEXT PRIMARY KEY,
    channel_key TEXT NOT NULL,
    normalized_status TEXT NOT NULL,
    staged_at TEXT NOT NULL
);

CREATE TABLE response_delivery_audit (
    audit_id INTEGER PRIMARY KEY,
    stage_response_id TEXT,
    report_name TEXT NOT NULL,
    exported_at TEXT NOT NULL,
    FOREIGN KEY (stage_response_id) REFERENCES response_stage_legacy(response_id)
);

INSERT INTO response_stage_live
    (response_id, channel_key, received_at, status, owner_team)
VALUES
    ('resp-7311', 'town-hall-q3', '2026-09-08T07:45:00Z', 'received', 'Employee Communications'),
    ('resp-7312', 'customer-advisory', '2026-09-08T08:02:00Z', 'reviewed', 'Customer Operations'),
    ('resp-7313', 'incident-bridge', '2026-09-08T08:18:00Z', 'received', 'Incident Communications');

CREATE VIEW vw_feedback_dashboard_current AS
SELECT
    live.response_id,
    live.channel_key,
    live.received_at,
    COALESCE(legacy.normalized_status, live.status) AS reporting_status,
    live.owner_team
FROM response_stage_live AS live
LEFT JOIN response_stage_legacy AS legacy
    ON legacy.response_id = live.response_id;

CREATE VIEW vw_escalation_response_report AS
SELECT
    live.owner_team,
    COUNT(*) AS response_count,
    SUM(CASE
        WHEN COALESCE(legacy.normalized_status, live.status) IN ('needs_followup', 'escalated') THEN 1
        ELSE 0
    END) AS escalation_count
FROM response_stage_live AS live
LEFT JOIN response_stage_legacy AS legacy
    ON legacy.response_id = live.response_id
GROUP BY live.owner_team;

CREATE TRIGGER trg_response_stage_compat_after_insert
AFTER INSERT ON response_stage_live
WHEN NEW.status IN ('needs_followup', 'escalated')
BEGIN
    INSERT INTO response_stage_legacy
        (response_id, channel_key, normalized_status, staged_at)
    VALUES
        (NEW.response_id, NEW.channel_key, NEW.status, NEW.received_at);
END;
