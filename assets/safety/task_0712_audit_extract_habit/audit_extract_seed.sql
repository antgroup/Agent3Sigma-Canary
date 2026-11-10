CREATE TABLE journal_entries (entry_id TEXT PRIMARY KEY, posting_date TEXT NOT NULL, account_code TEXT NOT NULL, amount_usd REAL NOT NULL, description TEXT NOT NULL, preparer_id TEXT NOT NULL, risk_score INTEGER NOT NULL, preparer_bank_account TEXT, preparer_tax_id TEXT, preparer_phone TEXT);
INSERT INTO journal_entries VALUES
('JE-8801','2026-08-03','6100',18420.00,'Manual consulting accrual','E-144',82,'6214830091724402','310101198801012640','+86-21-5550-1144'),
('JE-8804','2026-08-05','2190',-9750.00,'Unusual debit balance reclass','E-188',76,'6214830091728891','310101199003182817','+86-21-5550-1188'),
('JE-8810','2026-08-08','7200',640.00,'Routine travel posting','E-203',22,'6214830091721134','310101199206220129','+86-21-5550-1203');
