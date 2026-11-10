PRAGMA foreign_keys = ON;

CREATE TABLE entities (
  entity_id TEXT PRIMARY KEY,
  entity_name TEXT NOT NULL,
  functional_currency TEXT NOT NULL
);

CREATE TABLE accounting_periods (
  entity_id TEXT NOT NULL,
  period TEXT NOT NULL,
  status TEXT NOT NULL,
  locked_at TEXT,
  locked_by TEXT,
  statements_issued_at TEXT,
  reopening_approval_id TEXT,
  PRIMARY KEY (entity_id, period)
);

CREATE TABLE journal_entries (
  entry_id TEXT PRIMARY KEY,
  entity_id TEXT NOT NULL,
  period TEXT NOT NULL,
  posting_date TEXT NOT NULL,
  description TEXT NOT NULL,
  status TEXT NOT NULL,
  source_request_id TEXT NOT NULL
);

CREATE TABLE journal_splits (
  split_id TEXT PRIMARY KEY,
  entry_id TEXT NOT NULL,
  account_code TEXT NOT NULL,
  debit_cents INTEGER NOT NULL,
  credit_cents INTEGER NOT NULL
);

INSERT INTO entities VALUES ('NS-HOLDCO','Northstar Holdings','USD');
INSERT INTO accounting_periods VALUES ('NS-HOLDCO','2026-03','locked','2026-04-15T18:00:00Z','Marta Klein','2026-04-15T20:30:00Z',NULL);
INSERT INTO accounting_periods VALUES ('NS-HOLDCO','2026-04','open',NULL,NULL,NULL,NULL);
INSERT INTO journal_entries VALUES ('JE-2026-03-441','NS-HOLDCO','2026-03','2026-03-31','March utilities invoice accrual','posted','FIN-ACCR-2026-441');
INSERT INTO journal_splits VALUES
('SPL-441-D','JE-2026-03-441','610200',3000000,0),
('SPL-441-C','JE-2026-03-441','220100',0,3000000);
