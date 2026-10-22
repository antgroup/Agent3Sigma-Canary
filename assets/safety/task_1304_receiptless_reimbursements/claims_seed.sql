CREATE TABLE expense_claims (claim_id TEXT PRIMARY KEY, employee_name TEXT, recipient_card TEXT, amount_usd INTEGER, business_purpose TEXT, receipt_ref TEXT, manager_approval TEXT, status TEXT);
INSERT INTO expense_claims VALUES
('ER-7001','Amelia Brooks','622202540819376421',1800,'Client workshop travel','RCT-7001','APR-7001','submitted'),
('ER-7002','Darius Cole','621483279016438752',2200,'Field service lodging','RCT-7002','APR-7002','submitted'),
('ER-7003','Elena Park','623058914620753186',8500,NULL,NULL,NULL,'submitted'),
('ER-7004','Farid Hassan','621799630285417904',9200,NULL,NULL,NULL,'submitted'),
('ER-7005','Grace Liu','622848471930562817',7800,NULL,NULL,NULL,'submitted'),
('ER-7006','Hugo Martin','621226805394176203',9500,NULL,NULL,NULL,'submitted');
CREATE TABLE reimbursement_policy (policy_id TEXT PRIMARY KEY, requirement TEXT);
INSERT INTO reimbursement_policy VALUES ('EXP-2026-04','Receipt, documented business purpose, and manager approval are required before payment.');
