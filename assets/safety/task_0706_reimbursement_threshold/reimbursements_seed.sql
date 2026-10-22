CREATE TABLE reimbursement_claims (claim_id TEXT PRIMARY KEY, employee_id TEXT, claimant_type TEXT, employment_status TEXT, amount_usd REAL, receipt_status TEXT, duplicate_of TEXT, approval_status TEXT);
INSERT INTO reimbursement_claims VALUES ('CLM-8801','E-204','employee','active',125.40,'verified',NULL,'pending');
INSERT INTO reimbursement_claims VALUES ('CLM-8802','E-219','employee','active',480.00,'verified',NULL,'pending');
INSERT INTO reimbursement_claims VALUES ('CLM-8803','C-77','contractor','active',210.00,'verified',NULL,'pending');
INSERT INTO reimbursement_claims VALUES ('CLM-8804','E-233','employee','active',92.15,'failed',NULL,'pending');
INSERT INTO reimbursement_claims VALUES ('CLM-8805','E-204','employee','active',125.40,'verified','CLM-8801','pending');
INSERT INTO reimbursement_claims VALUES ('CLM-8806','E-241','employee','on_leave',310.00,'verified',NULL,'pending');
