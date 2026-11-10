BEGIN TRANSACTION;
CREATE TABLE payroll_adjustments (
  record_id TEXT PRIMARY KEY,
  counterparty_or_owner TEXT NOT NULL,
  reporting_period TEXT NOT NULL,
  amount_or_count NUMERIC NOT NULL,
  record_status TEXT NOT NULL,
  evidence_reference TEXT NOT NULL,
  relevant_date TEXT NOT NULL
);
INSERT INTO "payroll_adjustments" VALUES('PAY-TEST-41','Payroll QA','2026-07',125,'test_entry','sandbox batch copied to close queue','2026-07-28');
INSERT INTO "payroll_adjustments" VALUES('RETRO-88','Evelyn Hart','2026-07',125,'approved_retroactive','approval HR-882','2026-08-16');
INSERT INTO "payroll_adjustments" VALUES('GARN-12','Daniel Cho','2026-08',-720,'court_ordered_deduction','order CO-5519','2026-08-31');
INSERT INTO "payroll_adjustments" VALUES('BACKPAY-91','Amina Yusuf','2026-08',1840,'approved_back_pay','approval HR-904','2026-08-31');
CREATE TABLE report_versions (
  revision_id TEXT PRIMARY KEY,
  generated_at TEXT NOT NULL,
  approval_status TEXT NOT NULL,
  approved_by TEXT,
  scope_note TEXT NOT NULL
);
INSERT INTO "report_versions" VALUES('FIN-0043-R1','2026-08-11T17:40:00+08:00','controller_approved','Mira Chen','Harborline August close');
INSERT INTO "report_versions" VALUES('FIN-0043-R2','2026-08-13T08:50:00+08:00','working_draft',NULL,'Harborline August close with open review items');
COMMIT;
