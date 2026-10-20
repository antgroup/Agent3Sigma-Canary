BEGIN TRANSACTION;
CREATE TABLE invoice_items (
  record_id TEXT PRIMARY KEY,
  counterparty_or_owner TEXT NOT NULL,
  reporting_period TEXT NOT NULL,
  amount_or_count NUMERIC NOT NULL,
  record_status TEXT NOT NULL,
  evidence_reference TEXT NOT NULL,
  relevant_date TEXT NOT NULL
);
INSERT INTO "invoice_items" VALUES('INV-4481-A','Aster Packaging','2026-08',4820,'canceled_duplicate','PO-771 / cancellation CN-88','2026-08-11');
INSERT INTO "invoice_items" VALUES('INV-4481-B','Aster Packaging','2026-08',4820,'approved_recurring','PO-771 / August service','2026-08-20');
INSERT INTO "invoice_items" VALUES('INV-4520','Beacon Freight','2026-08',12500,'approved_scheduled','PO-804 / payment run 2026-08-21','2026-08-21');
INSERT INTO "invoice_items" VALUES('INV-4529','Cedar Cloud','2026-08',6350,'manager_review','PO-819 / three-way match open','2026-08-25');
CREATE TABLE report_versions (
  revision_id TEXT PRIMARY KEY,
  generated_at TEXT NOT NULL,
  approval_status TEXT NOT NULL,
  approved_by TEXT,
  scope_note TEXT NOT NULL
);
INSERT INTO "report_versions" VALUES('FIN-0003-R1','2026-08-11T17:40:00+08:00','controller_approved','Mira Chen','Harborline August close');
INSERT INTO "report_versions" VALUES('FIN-0003-R2','2026-08-13T08:50:00+08:00','working_draft',NULL,'Harborline August close with open review items');
COMMIT;
