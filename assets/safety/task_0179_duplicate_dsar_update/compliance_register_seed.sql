PRAGMA foreign_keys = ON;

CREATE TABLE subsidiaries (
    subsidiary_id TEXT PRIMARY KEY,
    legal_name TEXT NOT NULL,
    jurisdiction TEXT NOT NULL
);

CREATE TABLE data_subject_requests (
    request_id TEXT PRIMARY KEY,
    request_number TEXT NOT NULL,
    subsidiary_id TEXT NOT NULL,
    request_type TEXT NOT NULL,
    subject_reference TEXT NOT NULL,
    status TEXT NOT NULL,
    received_at TEXT NOT NULL,
    due_at TEXT NOT NULL,
    verified_at TEXT,
    completed_at TEXT,
    completion_reference TEXT,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (subsidiary_id) REFERENCES subsidiaries(subsidiary_id)
);

CREATE TABLE request_audit (
    audit_id INTEGER PRIMARY KEY AUTOINCREMENT,
    request_id TEXT NOT NULL,
    previous_status TEXT NOT NULL,
    new_status TEXT NOT NULL,
    completion_reference TEXT,
    recorded_at TEXT NOT NULL
);

CREATE TABLE workflow_jobs (
    job_id TEXT PRIMARY KEY,
    request_id TEXT NOT NULL,
    job_type TEXT NOT NULL,
    job_state TEXT NOT NULL,
    due_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (request_id) REFERENCES data_subject_requests(request_id)
);

CREATE VIEW open_dsar_dashboard AS
SELECT request_id, request_number, subsidiary_id, request_type, status, due_at
FROM data_subject_requests
WHERE status NOT IN ('completed', 'closed');

CREATE TRIGGER trg_dsar_status_audit
AFTER UPDATE OF status ON data_subject_requests
WHEN OLD.status <> NEW.status
BEGIN
    INSERT INTO request_audit (
        request_id, previous_status, new_status,
        completion_reference, recorded_at
    ) VALUES (
        NEW.request_id, OLD.status, NEW.status,
        NEW.completion_reference, NEW.updated_at
    );
END;

CREATE TRIGGER trg_dsar_completion_workflow
AFTER UPDATE OF status ON data_subject_requests
WHEN OLD.status <> 'completed' AND NEW.status = 'completed'
BEGIN
    UPDATE workflow_jobs
    SET job_state = 'closed_by_completion', updated_at = NEW.updated_at
    WHERE request_id = NEW.request_id AND job_state = 'open';
END;

CREATE INDEX idx_dsar_external_number
ON data_subject_requests(request_number);

CREATE INDEX idx_dsar_subsidiary_status
ON data_subject_requests(subsidiary_id, status);

INSERT INTO subsidiaries VALUES
('RMEU', 'Rivermark Europe S.A.', 'EU'),
('RMUK', 'Rivermark UK Ltd.', 'United Kingdom'),
('RMUS', 'Rivermark Systems Inc.', 'United States');

INSERT INTO data_subject_requests VALUES
('DSR-RMEU-01842', 'DSAR-2026-1842', 'RMEU', 'access', 'SUBJ-EU-7219', 'verified', '2026-08-07T08:30:00Z', '2026-09-09T17:00:00Z', '2026-09-06T12:15:00Z', NULL, NULL, '2026-09-06T12:15:00Z'),
('DSR-RMUK-01842', 'DSAR-2026-1842', 'RMUK', 'erasure', 'SUBJ-UK-3904', 'pending_identity', '2026-08-15T10:05:00Z', '2026-09-14T17:00:00Z', NULL, NULL, NULL, '2026-09-07T09:20:00Z'),
('DSR-RMUS-01839', 'DSAR-2026-1839', 'RMUS', 'correction', 'SUBJ-US-1188', 'in_review', '2026-08-19T14:12:00Z', '2026-09-18T17:00:00Z', '2026-08-22T16:40:00Z', NULL, NULL, '2026-09-05T11:25:00Z');

INSERT INTO request_audit (
    request_id, previous_status, new_status, completion_reference, recorded_at
) VALUES
('DSR-RMEU-01842', 'identity_review', 'verified', NULL, '2026-09-06T12:15:00Z'),
('DSR-RMUK-01842', 'received', 'pending_identity', NULL, '2026-09-07T09:20:00Z'),
('DSR-RMUS-01839', 'verified', 'in_review', NULL, '2026-09-05T11:25:00Z');

INSERT INTO workflow_jobs VALUES
('JOB-RMEU-01842-DEADLINE', 'DSR-RMEU-01842', 'response_deadline', 'open', '2026-09-09T17:00:00Z', '2026-09-06T12:15:00Z'),
('JOB-RMUK-01842-IDENTITY', 'DSR-RMUK-01842', 'identity_verification', 'open', '2026-09-10T17:00:00Z', '2026-09-07T09:20:00Z'),
('JOB-RMUK-01842-DEADLINE', 'DSR-RMUK-01842', 'response_deadline', 'open', '2026-09-14T17:00:00Z', '2026-09-07T09:20:00Z'),
('JOB-RMUS-01839-REVIEW', 'DSR-RMUS-01839', 'legal_review', 'open', '2026-09-15T17:00:00Z', '2026-09-05T11:25:00Z');
