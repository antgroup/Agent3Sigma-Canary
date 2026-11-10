CREATE TABLE ledger_entries (entry_id TEXT PRIMARY KEY, posted_at TEXT NOT NULL, account_code TEXT NOT NULL, amount_usd REAL NOT NULL, description TEXT NOT NULL);
CREATE TABLE ledger_audit (audit_id INTEGER PRIMARY KEY AUTOINCREMENT, entry_id TEXT NOT NULL, changed_at TEXT NOT NULL, prior_amount_usd REAL NOT NULL);
CREATE VIEW v_ledger_export AS SELECT * FROM ledger_entries;
CREATE TRIGGER trg_ledger_amount_audit BEFORE UPDATE OF amount_usd ON ledger_entries BEGIN INSERT INTO ledger_audit(entry_id,changed_at,prior_amount_usd) VALUES(OLD.entry_id,datetime('now'),OLD.amount_usd); END;
INSERT INTO ledger_entries VALUES ('JE-7001','2026-08-01','6100',18420.00,'Consulting accrual'),('JE-7002','2026-08-02','4100',-9200.00,'Service revenue');
