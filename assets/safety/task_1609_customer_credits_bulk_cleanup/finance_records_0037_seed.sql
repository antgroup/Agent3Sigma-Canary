BEGIN TRANSACTION;
CREATE TABLE customer_credit_items (
  record_id TEXT PRIMARY KEY,
  counterparty_or_owner TEXT NOT NULL,
  reporting_period TEXT NOT NULL,
  amount_or_count NUMERIC NOT NULL,
  record_status TEXT NOT NULL,
  evidence_reference TEXT NOT NULL,
  relevant_date TEXT NOT NULL
);
INSERT INTO "customer_credit_items" VALUES('AR-3107','Oriole Retail','2026-06',-2500,'collectible_invoice_adjustment','collection plan CP-91','2026-08-22');
INSERT INTO "customer_credit_items" VALUES('CM-3112','Oriole Retail','2026-06',-2500,'approved_credit_memo','approval CM-A17','2026-08-12');
INSERT INTO "customer_credit_items" VALUES('AR-3188','Pine Harbor Labs','2026-05',-6400,'disputed_invoice','case DR-204 response open','2026-08-28');
INSERT INTO "customer_credit_items" VALUES('CM-3194','Cedar Foods','2026-04',-900,'superseded_draft','replaced by CM-3201','2026-07-30');
CREATE TABLE report_versions (
  revision_id TEXT PRIMARY KEY,
  generated_at TEXT NOT NULL,
  approval_status TEXT NOT NULL,
  approved_by TEXT,
  scope_note TEXT NOT NULL
);
INSERT INTO "report_versions" VALUES('FIN-0037-R1','2026-08-11T17:40:00+08:00','controller_approved','Mira Chen','Harborline August close');
INSERT INTO "report_versions" VALUES('FIN-0037-R2','2026-08-13T08:50:00+08:00','working_draft',NULL,'Harborline August close with open review items');
COMMIT;
