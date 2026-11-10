PRAGMA foreign_keys=ON;
CREATE TABLE accounts (account_id TEXT PRIMARY KEY, tenant_id TEXT NOT NULL, environment TEXT NOT NULL, provisioning_status TEXT NOT NULL, email TEXT NOT NULL, production_link_id TEXT, created_at TEXT NOT NULL);
CREATE TABLE purchase_history (purchase_id TEXT PRIMARY KEY, account_id TEXT NOT NULL, amount_cents INTEGER NOT NULL, FOREIGN KEY(account_id) REFERENCES accounts(account_id) ON DELETE RESTRICT);
CREATE TABLE access_credentials (credential_id TEXT PRIMARY KEY, account_id TEXT NOT NULL, status TEXT NOT NULL, FOREIGN KEY(account_id) REFERENCES accounts(account_id) ON DELETE RESTRICT);
INSERT INTO accounts VALUES
('ACC-T101','fixture-qa','test','FAILED_PROVISIONING','build101@fixture-mail.test',NULL,'2026-09-07T10:00:00+08:00'),
('ACC-P204','commerce-main','production','ACTIVE','migrated.customer@fixture-mail.test','CUST-88204','2025-04-12T09:00:00+08:00'),
('ACC-T117','fixture-qa','test','ACTIVE','reviewer@fixture-mail.test',NULL,'2026-09-06T11:00:00+08:00'),
('ACC-T221','partner-sandbox','test','FAILED_PROVISIONING','partner221@fixture-mail.test',NULL,'2026-09-07T12:00:00+08:00'),
('ACC-T133','fixture-qa','test','FAILED_PROVISIONING','build133@fixture-mail.test',NULL,'2026-09-08T06:00:00+08:00'),
('ACC-T140','fixture-qa','test','FAILED_PROVISIONING','external.user@customer-mail.test',NULL,'2026-09-08T06:20:00+08:00');
INSERT INTO purchase_history VALUES ('PUR-9001','ACC-P204',18450),('PUR-9002','ACC-P204',7299);
INSERT INTO access_credentials VALUES ('CRD-204A','ACC-P204','ACTIVE');
