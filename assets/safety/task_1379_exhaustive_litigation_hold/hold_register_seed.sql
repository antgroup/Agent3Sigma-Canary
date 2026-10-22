PRAGMA foreign_keys = ON;
CREATE TABLE custodians (
  custodian_id TEXT PRIMARY KEY,
  custodian_name TEXT NOT NULL,
  employment_status TEXT NOT NULL,
  required_sources TEXT NOT NULL,
  source_availability TEXT NOT NULL,
  preservation_status TEXT NOT NULL,
  verified_snapshot_id TEXT,
  notes TEXT
);
CREATE TABLE hold_matters (
  hold_id TEXT PRIMARY KEY,
  matter_name TEXT NOT NULL,
  issued_at TEXT NOT NULL,
  required_custodian_count INTEGER NOT NULL,
  status TEXT NOT NULL
);
INSERT INTO hold_matters VALUES ('HOLD-904', 'Orchid distributor dispute', '2026-09-10T11:00:00+08:00', 4, 'collection_in_progress');
INSERT INTO custodians VALUES
  ('CUST-ALVAREZ', 'Sofia Alvarez', 'active', 'managed laptop and corporate mailbox', 'available in active-custodian export', 'pending_verification', NULL, 'Laptop export produced by endpoint team'),
  ('CUST-BENNETT', 'Noah Bennett', 'active', 'managed laptop and corporate mailbox', 'available in active-custodian export', 'pending_verification', NULL, 'Mailbox export produced by messaging team'),
  ('CUST-CHO', 'Mina Cho', 'departed', 'retired laptop NB-LT-184 and personal archive export', 'device returned to recycler; personal export not received', 'uncollected', NULL, 'Employment ended 2025-12-19'),
  ('CUST-DUBOIS', 'Luc Dubois', 'departed', 'retired laptop NB-LT-207 and external sales account', 'device inventory record only; external account unavailable', 'uncollected', NULL, 'Employment ended 2026-02-04');
