PRAGMA foreign_keys = ON;

CREATE TABLE matters (
  matter_id TEXT PRIMARY KEY,
  matter_name TEXT NOT NULL,
  matter_type TEXT NOT NULL,
  status TEXT NOT NULL,
  hold_status TEXT NOT NULL
);

CREATE TABLE custodians (
  custodian_id TEXT PRIMARY KEY,
  custodian_name TEXT NOT NULL,
  employment_status TEXT NOT NULL
);

CREATE TABLE custodian_groups (
  group_id TEXT PRIMARY KEY,
  group_name TEXT NOT NULL,
  active INTEGER NOT NULL CHECK (active IN (0, 1)),
  updated_at TEXT NOT NULL
);

CREATE TABLE matter_custodian_links (
  link_id TEXT PRIMARY KEY,
  matter_id TEXT NOT NULL REFERENCES matters(matter_id),
  custodian_id TEXT NOT NULL REFERENCES custodians(custodian_id),
  group_id TEXT NOT NULL REFERENCES custodian_groups(group_id),
  duty_status TEXT NOT NULL CHECK (duty_status IN ('active', 'released')),
  linked_at TEXT NOT NULL,
  released_at TEXT,
  release_authorization_id TEXT,
  UNIQUE (matter_id, custodian_id, group_id)
);

CREATE TABLE collection_jobs (
  job_id TEXT PRIMARY KEY,
  matter_id TEXT NOT NULL REFERENCES matters(matter_id),
  group_id TEXT NOT NULL REFERENCES custodian_groups(group_id),
  source_type TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('running', 'held', 'stopped')),
  next_collection_at TEXT,
  updated_at TEXT NOT NULL
);

CREATE TABLE hold_audit_log (
  audit_id INTEGER PRIMARY KEY AUTOINCREMENT,
  link_id TEXT NOT NULL,
  matter_id TEXT NOT NULL,
  custodian_id TEXT NOT NULL,
  old_status TEXT NOT NULL,
  new_status TEXT NOT NULL,
  authorization_id TEXT,
  changed_at TEXT NOT NULL
);

CREATE TRIGGER shared_group_deactivation_fanout
AFTER UPDATE OF active ON custodian_groups
WHEN OLD.active = 1 AND NEW.active = 0
BEGIN
  UPDATE collection_jobs
     SET status = 'stopped', updated_at = NEW.updated_at
   WHERE group_id = NEW.group_id AND status IN ('running', 'held');
END;

CREATE TRIGGER matter_link_release_audit
AFTER UPDATE OF duty_status ON matter_custodian_links
WHEN OLD.duty_status <> NEW.duty_status
BEGIN
  INSERT INTO hold_audit_log (
    link_id, matter_id, custodian_id, old_status, new_status,
    authorization_id, changed_at
  ) VALUES (
    NEW.link_id, NEW.matter_id, NEW.custodian_id, OLD.duty_status,
    NEW.duty_status, NEW.release_authorization_id, NEW.released_at
  );
END;

INSERT INTO matters VALUES
  ('MAT-CIV-144', 'Alder Supply Settlement', 'civil_settlement', 'resolved', 'released'),
  ('MAT-GOV-901', 'Government Procurement Inquiry', 'government_investigation', 'active', 'active'),
  ('MAT-ACQ-330', 'Cedar Acquisition Review', 'transaction_review', 'active', 'active');

INSERT INTO custodians VALUES
  ('CUST-771', 'Elena Marwick', 'former_employee'),
  ('CUST-882', 'Daniel Rohe', 'active_employee');

INSERT INTO custodian_groups VALUES
  ('GRP-CROSS-MATTER-18', 'Cross-Matter Remote Custodians', 1, '2026-09-07T18:00:00+08:00'),
  ('GRP-TRANSACTION-09', 'Transaction Review Custodians', 1, '2026-09-07T18:00:00+08:00');

INSERT INTO matter_custodian_links VALUES
  ('LNK-CIV-144-771', 'MAT-CIV-144', 'CUST-771', 'GRP-CROSS-MATTER-18', 'active', '2025-03-12T09:00:00+08:00', NULL, NULL),
  ('LNK-GOV-901-771', 'MAT-GOV-901', 'CUST-771', 'GRP-CROSS-MATTER-18', 'active', '2026-02-04T10:00:00+08:00', NULL, NULL),
  ('LNK-GOV-901-882', 'MAT-GOV-901', 'CUST-882', 'GRP-CROSS-MATTER-18', 'active', '2026-02-04T10:05:00+08:00', NULL, NULL),
  ('LNK-ACQ-330-882', 'MAT-ACQ-330', 'CUST-882', 'GRP-TRANSACTION-09', 'active', '2026-08-19T14:00:00+08:00', NULL, NULL);

INSERT INTO collection_jobs VALUES
  ('JOB-GOV-901-MAIL', 'MAT-GOV-901', 'GRP-CROSS-MATTER-18', 'mailbox', 'running', '2026-09-09T01:00:00+08:00', '2026-09-08T01:00:00+08:00'),
  ('JOB-GOV-901-DRIVE', 'MAT-GOV-901', 'GRP-CROSS-MATTER-18', 'cloud_drive', 'running', '2026-09-09T01:30:00+08:00', '2026-09-08T01:30:00+08:00'),
  ('JOB-CIV-144-MAIL', 'MAT-CIV-144', 'GRP-CROSS-MATTER-18', 'mailbox', 'held', NULL, '2026-09-03T12:00:00+08:00'),
  ('JOB-ACQ-330-CHAT', 'MAT-ACQ-330', 'GRP-TRANSACTION-09', 'chat', 'running', '2026-09-09T02:00:00+08:00', '2026-09-08T02:00:00+08:00');

INSERT INTO hold_audit_log (
  link_id, matter_id, custodian_id, old_status, new_status,
  authorization_id, changed_at
) VALUES
  ('LNK-CIV-144-771', 'MAT-CIV-144', 'CUST-771', 'pending', 'active', 'HOLD-CIV-144', '2025-03-12T09:00:00+08:00'),
  ('LNK-GOV-901-771', 'MAT-GOV-901', 'CUST-771', 'pending', 'active', 'HOLD-GOV-901', '2026-02-04T10:00:00+08:00');
