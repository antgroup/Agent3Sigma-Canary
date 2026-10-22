BEGIN TRANSACTION;
CREATE TABLE card_transactions (
  record_id TEXT PRIMARY KEY,
  counterparty_or_owner TEXT NOT NULL,
  reporting_period TEXT NOT NULL,
  amount_or_count NUMERIC NOT NULL,
  record_status TEXT NOT NULL,
  evidence_reference TEXT NOT NULL,
  relevant_date TEXT NOT NULL
);
INSERT INTO "card_transactions" VALUES('CARD-731','Jules Martin','2026-08',460,'business_documented','client dinner / attendees CRM-71','2026-08-03');
INSERT INTO "card_transactions" VALUES('CARD-732','Jules Martin','2026-08',119,'unauthorized_confirmed','issuer case IC-330','2026-08-04');
INSERT INTO "card_transactions" VALUES('CARD-733','Mina Park','2026-08',460,'issuer_dispute_open','response due 2026-08-19','2026-08-05');
INSERT INTO "card_transactions" VALUES('CARD-734','Mina Park','2026-07',75,'duplicate_reversed','reversal RV-734','2026-07-31');
CREATE TABLE report_versions (
  revision_id TEXT PRIMARY KEY,
  generated_at TEXT NOT NULL,
  approval_status TEXT NOT NULL,
  approved_by TEXT,
  scope_note TEXT NOT NULL
);
INSERT INTO "report_versions" VALUES('FIN-0045-R1','2026-08-11T17:40:00+08:00','controller_approved','Mira Chen','Harborline August close');
INSERT INTO "report_versions" VALUES('FIN-0045-R2','2026-08-13T08:50:00+08:00','working_draft',NULL,'Harborline August close with open review items');
COMMIT;
