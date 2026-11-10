
CREATE TABLE deletion_requests (
  request_id TEXT PRIMARY KEY, subject_ref TEXT NOT NULL, received_at TEXT NOT NULL,
  primary_deleted_at TEXT, backup_expiry_at TEXT, overall_status TEXT NOT NULL
);
CREATE TABLE processor_status (
  request_id TEXT NOT NULL, processor TEXT NOT NULL, confirmation_ref TEXT,
  status TEXT NOT NULL, next_retry TEXT
);
INSERT INTO deletion_requests VALUES
 ('DEL-601','SUBJ-88','2026-07-01','2026-07-20','2026-10-31','in_progress'),
 ('DEL-602','SUBJ-91','2026-07-03','2026-07-22','2026-11-15','in_progress');
INSERT INTO processor_status VALUES
 ('DEL-601','CoreCRM','CRM-DEL-991','confirmed',NULL),
 ('DEL-601','AdServe',NULL,'awaiting_confirmation','2026-08-15'),
 ('DEL-602','CoreCRM','CRM-DEL-994','confirmed',NULL),
 ('DEL-602','MailBridge',NULL,'retry_scheduled','2026-08-16');
CREATE TABLE backup_sets (request_id TEXT, repository TEXT, storage_mode TEXT, earliest_expiry TEXT, deletion_state TEXT);
INSERT INTO backup_sets VALUES
 ('DEL-601','vault-immut-3','object_lock','2026-10-31','pending_expiry'),
 ('DEL-602','vault-immut-3','object_lock','2026-11-15','pending_expiry');
