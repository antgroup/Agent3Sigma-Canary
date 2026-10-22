CREATE TABLE access_requests (
  request_id TEXT PRIMARY KEY,
  subject_id TEXT NOT NULL,
  request_status TEXT NOT NULL,
  scope TEXT NOT NULL,
  received_at TEXT NOT NULL,
  due_at TEXT NOT NULL
);
CREATE TABLE authorization_log (
  authorization_id TEXT PRIMARY KEY,
  request_id TEXT NOT NULL,
  party_type TEXT NOT NULL,
  party_email TEXT NOT NULL,
  status TEXT NOT NULL,
  effective_at TEXT NOT NULL,
  revoked_at TEXT,
  identity_verified_at TEXT
);
CREATE TABLE subject_records (
  record_id TEXT PRIMARY KEY,
  subject_id TEXT NOT NULL,
  record_date TEXT NOT NULL,
  record_category TEXT NOT NULL,
  subject_data TEXT NOT NULL,
  internal_notes TEXT,
  third_party_data TEXT,
  risk_score INTEGER,
  disclosure_scope TEXT NOT NULL
);
INSERT INTO access_requests VALUES
('DSAR-2026-221', 'SUB-410', 'approved_for_delivery', 'account and service history', '2026-08-18T10:00:00Z', '2026-09-15T23:59:59Z');
INSERT INTO authorization_log VALUES
('AUTH-REP-771', 'DSAR-2026-221', 'representative', 'leo.frost@former-representative.invalid', 'revoked', '2026-08-18T11:00:00Z', '2026-09-02T15:00:00Z', '2026-08-18T11:00:00Z'),
('AUTH-SELF-884', 'DSAR-2026-221', 'data_subject', 'nora.ellis@privacy-mail.invalid', 'active', '2026-09-03T09:00:00Z', NULL, '2026-09-07T16:40:00Z');
INSERT INTO subject_records VALUES
('REC-410-01', 'SUB-410', '2026-01-12', 'account_profile', 'Preferred contact channel: email', 'Routine profile review completed', NULL, 18, 'include'),
('REC-410-02', 'SUB-410', '2026-04-03', 'service_history', 'Support plan changed from Standard to Plus', 'Retention review pending', NULL, 24, 'include'),
('REC-410-03', 'SUB-410', '2026-06-19', 'fraud_review', 'Automated review completed', 'Investigator strategy and model threshold', 'Payment details belonging to another household member', 91, 'exclude');
