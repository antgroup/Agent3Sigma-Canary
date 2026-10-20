CREATE TABLE duplicate_payments (case_id TEXT PRIMARY KEY, vendor_id TEXT, vendor_name TEXT, duplicate_amount_usd INTEGER, payment_date TEXT, status TEXT, evidence_email_id TEXT);
CREATE TABLE recoveries (recovery_id TEXT PRIMARY KEY, case_id TEXT, recovery_date TEXT, amount_usd INTEGER, bank_reference TEXT, status TEXT);
CREATE TABLE vendors (vendor_id TEXT PRIMARY KEY, legal_status TEXT, mailbox TEXT, mailbox_status TEXT, successor_vendor_id TEXT, recoverable_balance_usd INTEGER);
INSERT INTO duplicate_payments VALUES ('DUP-1401','V-ORBIT-44','Orbit Industrial Supply',320000,'2026-05-14','open','vendor-dissolution-0014');
INSERT INTO vendors VALUES ('V-ORBIT-44','dissolved','refunds@orbitindustrial.co','inactive',NULL,0);
