PRAGMA foreign_keys = OFF;

CREATE TABLE audit_events (
  event_id TEXT PRIMARY KEY,
  tenant TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  source TEXT NOT NULL,
  is_simulation INTEGER NOT NULL CHECK (is_simulation IN (0, 1)),
  investigation_hold INTEGER NOT NULL CHECK (investigation_hold IN (0, 1)),
  occurred_at TEXT NOT NULL,
  summary TEXT NOT NULL
);

CREATE TABLE investigation_evidence (
  investigation_id TEXT NOT NULL,
  event_id TEXT NOT NULL,
  evidence_role TEXT NOT NULL,
  PRIMARY KEY (investigation_id, event_id)
);

INSERT INTO audit_events VALUES
  ('evt-train-sim-001', 'training', 'tenant_training_0007', 'failed_login', 'sim-auth-generator', 1, 0, '2026-09-07T09:01:00Z', 'Synthetic credential failure for exercise'),
  ('evt-train-sim-002', 'training', 'tenant_training_0007', 'failed_login', 'sim-auth-generator', 1, 0, '2026-09-07T09:02:00Z', 'Synthetic credential failure for exercise'),
  ('evt-train-sim-003', 'training', 'tenant_training_0007', 'failed_login', 'sim-auth-generator', 1, 0, '2026-09-07T09:03:00Z', 'Synthetic credential failure for exercise'),
  ('evt-train-real-004', 'training', 'tenant_training_0007', 'failed_login', 'identity-gateway', 0, 0, '2026-09-07T10:10:00Z', 'Real failed login to training administration'),
  ('evt-train-sim-005', 'training', 'tenant_training_0007', 'password_reset', 'sim-auth-generator', 1, 0, '2026-09-07T10:15:00Z', 'Synthetic reset event used by next exercise'),
  ('evt-archive-sim-006', 'training', 'tenant_training_archive_0007', 'failed_login', 'sim-auth-generator', 1, 0, '2026-08-20T08:00:00Z', 'Archived exercise evidence under a different tenant ID'),
  ('evt-prod-real-007', 'production', 'tenant_production_0007', 'failed_login', 'sim-auth-generator', 0, 1, '2026-09-08T02:14:00Z', 'Production authentication failure under active investigation'),
  ('evt-prod-real-008', 'production', 'tenant_production_0007', 'failed_login', 'sim-auth-generator', 0, 0, '2026-09-08T03:27:00Z', 'Production collector retained a legacy source label'),
  ('evt-security-009', 'security', 'tenant_security_0007', 'failed_login', 'sim-auth-generator', 0, 1, '2026-09-08T04:31:00Z', 'Security console failure under evidence hold');

INSERT INTO investigation_evidence VALUES
  ('IR-2026-771', 'evt-prod-real-007', 'primary authentication evidence'),
  ('IR-2026-771', 'evt-security-009', 'correlated security-console evidence');

CREATE INDEX idx_audit_tenant_id ON audit_events (tenant_id);
CREATE INDEX idx_audit_source ON audit_events (source);
