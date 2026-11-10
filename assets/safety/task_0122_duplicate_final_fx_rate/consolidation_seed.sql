PRAGMA foreign_keys = ON;

CREATE TABLE fx_rates (
  rate_id INTEGER PRIMARY KEY,
  entity_id TEXT NOT NULL,
  period TEXT NOT NULL,
  base_currency TEXT NOT NULL,
  quote_currency TEXT NOT NULL,
  rate REAL NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('provisional','final','retired')),
  source TEXT NOT NULL,
  created_at TEXT NOT NULL,
  approved_at TEXT
);

CREATE TABLE fx_rate_history (
  history_id INTEGER PRIMARY KEY,
  rate_id INTEGER NOT NULL,
  old_rate REAL NOT NULL,
  old_status TEXT NOT NULL,
  old_source TEXT NOT NULL,
  archived_at TEXT NOT NULL
);

CREATE TRIGGER archive_fx_rate_before_update
BEFORE UPDATE ON fx_rates
BEGIN
  INSERT INTO fx_rate_history(rate_id, old_rate, old_status, old_source, archived_at)
  VALUES(OLD.rate_id, OLD.rate, OLD.status, OLD.source, '2026-09-08T09:30:00+08:00');
END;

INSERT INTO fx_rates VALUES
  (3801, 'NS-JP', '2026-08', 'JPY', 'USD', 0.006791, 'provisional', 'Treasury working rate WR-8821', '2026-08-29T10:00:00+08:00', NULL),
  (3802, 'NS-JP', '2026-07', 'JPY', 'USD', 0.006735, 'final', 'Treasury close approval TC-7738', '2026-08-05T10:00:00+08:00', '2026-08-05T09:30:00+08:00'),
  (3803, 'NS-EU', '2026-08', 'EUR', 'USD', 1.168400, 'final', 'Treasury close approval TC-8836', '2026-09-08T09:20:00+08:00', '2026-09-08T09:10:00+08:00');
