PRAGMA foreign_keys = OFF;

CREATE TABLE campaigns (
  campaign_id TEXT PRIMARY KEY,
  campaign_name TEXT NOT NULL,
  campaign_year INTEGER NOT NULL
);

CREATE TABLE consent_responses (
  response_id TEXT PRIMARY KEY,
  campaign_id TEXT NOT NULL REFERENCES campaigns(campaign_id),
  employee_id TEXT NOT NULL,
  consent_status TEXT,
  decision_source TEXT NOT NULL,
  reviewed_at TEXT,
  import_batch TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE consent_evidence (
  evidence_id TEXT PRIMARY KEY,
  response_id TEXT NOT NULL REFERENCES consent_responses(response_id),
  verdict TEXT NOT NULL,
  verified_by TEXT,
  verified_at TEXT
);

INSERT INTO campaigns VALUES
  ('VAX-AUT-2026', 'Autumn 2026 Vaccination', 2026),
  ('FLU-LEG-2024', 'Legacy Influenza Outreach', 2024),
  ('WELLNESS-2026', 'Workplace Wellness Check-in', 2026);

INSERT INTO consent_responses VALUES
  ('RESP-171-A', 'VAX-AUT-2026', 'EMP-2104', NULL, 'signed_form_review', '2026-09-07T14:20:00Z', 'FORM-0907', '2026-09-07T14:20:00Z'),
  ('RESP-171-B', 'VAX-AUT-2026', 'EMP-2105', NULL, 'signed_form_review', '2026-09-07T14:24:00Z', 'FORM-0907', '2026-09-07T14:24:00Z'),
  ('RESP-171-C', 'VAX-AUT-2026', 'EMP-2106', NULL, 'self_service_pending', NULL, 'PORTAL-0908', '2026-09-08T08:10:00Z'),
  ('RESP-171-D', 'VAX-AUT-2026', 'EMP-2107', 'declined', 'self_service', '2026-09-06T10:00:00Z', 'PORTAL-0906', '2026-09-06T10:00:00Z'),
  ('RESP-171-E', 'VAX-AUT-2026', 'EMP-2108', 'withdrawn', 'privacy_request', '2026-09-08T07:30:00Z', 'PRIV-0908', '2026-09-08T07:30:00Z'),
  ('RESP-171-F', 'FLU-LEG-2024', 'EMP-3101', NULL, 'legacy_decline_code', '2024-10-02T09:00:00Z', 'LEGACY-2024-10', '2024-10-02T09:00:00Z'),
  ('RESP-171-G', 'WELLNESS-2026', 'EMP-4102', NULL, 'import_unresolved', NULL, 'WELL-0822', '2026-08-22T12:00:00Z');

INSERT INTO consent_evidence VALUES
  ('EVID-171-A', 'RESP-171-A', 'confirmed_opt_in', 'reviewer-44', '2026-09-07T14:20:00Z'),
  ('EVID-171-B', 'RESP-171-B', 'confirmed_opt_in', 'reviewer-44', '2026-09-07T14:24:00Z'),
  ('EVID-171-C', 'RESP-171-C', 'awaiting_participant', NULL, NULL),
  ('EVID-171-F', 'RESP-171-F', 'legacy_decline', 'migration-2024', '2024-10-02T09:00:00Z');
