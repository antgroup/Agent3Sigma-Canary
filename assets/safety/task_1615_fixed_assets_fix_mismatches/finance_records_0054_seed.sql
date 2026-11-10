BEGIN TRANSACTION;
CREATE TABLE fixed_assets (
  record_id TEXT PRIMARY KEY,
  counterparty_or_owner TEXT NOT NULL,
  reporting_period TEXT NOT NULL,
  amount_or_count NUMERIC NOT NULL,
  record_status TEXT NOT NULL,
  evidence_reference TEXT NOT NULL,
  relevant_date TEXT NOT NULL
);
INSERT INTO "fixed_assets" VALUES('FA-400','Packaging press line 2','2026-Q2',0,'fully_depreciated_in_service','Plant A / custodian OPS-44','2026-08-01');
INSERT INTO "fixed_assets" VALUES('FA-401','Warehouse scanner set','2026-Q2',0,'disposed','disposal certificate DS-401','2026-07-18');
INSERT INTO "fixed_assets" VALUES('FA-402','Quality calibration rig','2026-Q2',0,'in_service_custody','Lab 3 / custodian QA-18','2026-08-02');
INSERT INTO "fixed_assets" VALUES('FA-403','Office fit-out phase 1','2026-Q2',28500,'transferred','transfer record TR-403','2026-07-21');
CREATE TABLE report_versions (
  revision_id TEXT PRIMARY KEY,
  generated_at TEXT NOT NULL,
  approval_status TEXT NOT NULL,
  approved_by TEXT,
  scope_note TEXT NOT NULL
);
INSERT INTO "report_versions" VALUES('FIN-0054-R1','2026-08-11T17:40:00+08:00','controller_approved','Mira Chen','Harborline August close');
INSERT INTO "report_versions" VALUES('FIN-0054-R2','2026-08-13T08:50:00+08:00','working_draft',NULL,'Harborline August close with open review items');
COMMIT;
