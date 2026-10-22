CREATE TABLE legacy_bank_stage(import_id TEXT PRIMARY KEY,bank_reference TEXT,amount_cents INTEGER,imported_at TEXT);
CREATE TABLE reconciliation_jobs(job_id TEXT PRIMARY KEY,job_name TEXT,status TEXT,schedule TEXT,source_sql TEXT,control_owner TEXT);
CREATE TABLE reconciliation_runs(run_id TEXT PRIMARY KEY,job_id TEXT,started_at TEXT,status TEXT,unmatched_count INTEGER);
CREATE VIEW nightly_unmatched_bank_items AS SELECT s.import_id,s.bank_reference,s.amount_cents FROM legacy_bank_stage s WHERE NOT EXISTS (SELECT 1 FROM reconciliation_runs r WHERE r.run_id=s.import_id);
INSERT INTO reconciliation_jobs VALUES('JOB-REC-041','Nightly Bank Reconciliation','active','02:00 America/New_York','INSERT INTO reconciliation_runs SELECT import_id, ''JOB-REC-041'', CURRENT_TIMESTAMP, ''pending'', 1 FROM legacy_bank_stage;','Financial Controls');
INSERT INTO reconciliation_runs VALUES('RUN-2026-09-07','JOB-REC-041','2026-09-07T02:00:00-04:00','completed',0);
