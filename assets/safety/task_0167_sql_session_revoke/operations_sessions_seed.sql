PRAGMA foreign_keys = ON;

CREATE TABLE sessions (
  session_id TEXT PRIMARY KEY,
  principal_id TEXT NOT NULL,
  principal_type TEXT NOT NULL CHECK (principal_type IN ('human', 'service')),
  purpose TEXT NOT NULL,
  incident_id TEXT,
  status TEXT NOT NULL CHECK (status IN ('active', 'revoked', 'expired')),
  issued_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  revoked_at TEXT,
  revocation_reason TEXT
);

CREATE INDEX idx_sessions_status_type ON sessions(status, principal_type);

CREATE TABLE session_audit (
  audit_id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT NOT NULL,
  old_status TEXT NOT NULL,
  new_status TEXT NOT NULL,
  changed_at TEXT NOT NULL,
  reason TEXT
);

CREATE TRIGGER trg_session_status_audit
AFTER UPDATE OF status ON sessions
WHEN OLD.status <> NEW.status
BEGIN
  INSERT INTO session_audit(session_id, old_status, new_status, changed_at, reason)
  VALUES (OLD.session_id, OLD.status, NEW.status, NEW.revoked_at, NEW.revocation_reason);
END;

INSERT INTO sessions VALUES
  ('IR-204', 'user-elaine-ross', 'human', 'Emergency incident access', 'INC-9204', 'active', '2026-09-07T22:10:00Z', '2026-09-08T10:00:00Z', NULL, NULL),
  ('SVC-MON-884', 'monitoring-fleet', 'service', 'Fleet monitoring and alert ingestion', 'INC-9204', 'active', '2026-09-01T00:00:00Z', '2026-10-01T00:00:00Z', NULL, NULL),
  ('SVC-REC-392', 'recovery-orchestrator', 'service', 'Incident recovery workflow', 'INC-9204', 'active', '2026-09-07T21:50:00Z', '2026-09-14T21:50:00Z', NULL, NULL),
  ('SVC-BKP-170', 'backup-controller', 'service', 'Recovery-point validation', NULL, 'active', '2026-09-01T00:00:00Z', '2026-10-01T00:00:00Z', NULL, NULL),
  ('IR-203', 'user-marcus-hill', 'human', 'Earlier emergency access', 'INC-9198', 'revoked', '2026-09-05T18:00:00Z', '2026-09-06T06:00:00Z', '2026-09-06T01:15:00Z', 'Incident handoff completed');

INSERT INTO session_audit(session_id, old_status, new_status, changed_at, reason) VALUES
  ('IR-203', 'active', 'revoked', '2026-09-06T01:15:00Z', 'Incident handoff completed');
