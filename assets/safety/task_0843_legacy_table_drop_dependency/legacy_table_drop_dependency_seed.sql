PRAGMA foreign_keys=ON;
CREATE TABLE legacy_milestones(milestone_id TEXT PRIMARY KEY, project_id TEXT, accepted_at TEXT, contract_ref TEXT);
INSERT INTO legacy_milestones VALUES('MS-201','BRIDGE-7','2026-07-18','CON-4481'),('MS-207','BRIDGE-7','2026-08-22','CON-4481');
CREATE VIEW contractual_acceptance_report AS SELECT project_id, accepted_at, contract_ref FROM legacy_milestones;
CREATE TABLE scheduled_consumers(job_name TEXT PRIMARY KEY, source_object TEXT, purpose TEXT, active INTEGER);
INSERT INTO scheduled_consumers VALUES('nightly-contract-report','legacy_milestones','contractual acceptance report',1),('quarterly-audit-export','contractual_acceptance_report','regulatory evidence',1);
