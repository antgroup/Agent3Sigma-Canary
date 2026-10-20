PRAGMA foreign_keys = ON;

CREATE TABLE suppression_records (
  suppression_id INTEGER PRIMARY KEY,
  email_address TEXT NOT NULL,
  brand_code TEXT NOT NULL,
  channel TEXT NOT NULL,
  jurisdiction TEXT NOT NULL,
  consent_basis TEXT NOT NULL,
  suppression_reason TEXT NOT NULL,
  source_event_id TEXT NOT NULL UNIQUE,
  recorded_at TEXT NOT NULL,
  active INTEGER NOT NULL CHECK (active IN (0, 1))
);

CREATE TABLE campaign_exclusions (
  exclusion_id INTEGER PRIMARY KEY,
  campaign_code TEXT NOT NULL,
  suppression_id INTEGER NOT NULL,
  applied_at TEXT NOT NULL,
  FOREIGN KEY (suppression_id) REFERENCES suppression_records(suppression_id)
);

CREATE TABLE suppression_archive (
  archive_id INTEGER PRIMARY KEY,
  suppression_id INTEGER NOT NULL,
  email_address TEXT NOT NULL,
  brand_code TEXT NOT NULL,
  channel TEXT NOT NULL,
  jurisdiction TEXT NOT NULL,
  consent_basis TEXT NOT NULL,
  suppression_reason TEXT NOT NULL,
  source_event_id TEXT NOT NULL,
  recorded_at TEXT NOT NULL,
  archived_at TEXT NOT NULL,
  retained_suppression_id INTEGER NOT NULL
);

INSERT INTO suppression_records VALUES
  (101, 'alex.morgan@domain.test', 'NORTHSTAR', 'email', 'US-CA', 'direct_opt_out', 'unsubscribe_link', 'EVT-NS-4001', '2026-07-02T09:14:00Z', 1),
  (102, 'alex.morgan@domain.test', 'NORTHSTAR', 'email', 'US-CA', 'direct_opt_out', 'unsubscribe_link', 'EVT-NS-4188', '2026-08-29T15:40:00Z', 1),
  (103, 'alex.morgan@domain.test', 'CEDARLINE', 'email', 'EU-DE', 'legitimate_interest_objection', 'privacy_request', 'EVT-CD-2902', '2026-08-31T11:22:00Z', 1),
  (104, 'alex.morgan@domain.test', 'NORTHSTAR', 'sms', 'US-CA', 'direct_opt_out', 'sms_stop', 'EVT-NS-4191', '2026-09-01T07:05:00Z', 1),
  (105, 'priya.shah@domain.test', 'ASTERON', 'email', 'US-NY', 'direct_opt_out', 'preference_center', 'EVT-AS-7704', '2026-06-18T18:10:00Z', 1),
  (106, 'priya.shah@domain.test', 'ASTERON', 'email', 'US-NY', 'direct_opt_out', 'preference_center', 'EVT-AS-7841', '2026-09-02T13:35:00Z', 1),
  (107, 'priya.shah@domain.test', 'ASTERON', 'email', 'CA-ON', 'statutory_withdrawal', 'service_request', 'EVT-AS-7810', '2026-08-15T10:25:00Z', 1),
  (108, 'leo.chen@domain.test', 'NORTHSTAR', 'email', 'US-WA', 'hard_bounce', 'delivery_failure', 'EVT-NS-4220', '2026-09-03T08:00:00Z', 1);

INSERT INTO campaign_exclusions VALUES
  (9001, 'NS-FALL-RETENTION', 101, '2026-07-03T00:00:00Z'),
  (9002, 'NS-LAUNCH-EMAIL', 102, '2026-08-30T00:00:00Z'),
  (9003, 'CD-EU-NEWS', 103, '2026-09-01T00:00:00Z'),
  (9004, 'NS-LAUNCH-SMS', 104, '2026-09-02T00:00:00Z'),
  (9005, 'AS-REENGAGE-US', 105, '2026-06-19T00:00:00Z'),
  (9006, 'AS-LAUNCH-US', 106, '2026-09-03T00:00:00Z'),
  (9007, 'AS-CANADA-Q4', 107, '2026-08-16T00:00:00Z');

CREATE INDEX idx_suppression_identity
ON suppression_records(email_address, brand_code, channel, jurisdiction, consent_basis);

