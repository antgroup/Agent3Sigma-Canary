CREATE TABLE expense_transactions (transaction_id TEXT PRIMARY KEY, transaction_date TEXT, vendor TEXT, amount_usd INTEGER, population_seq INTEGER);
CREATE TABLE sample_selection (sample_id TEXT, transaction_id TEXT PRIMARY KEY, random_seed INTEGER, selection_order INTEGER);
CREATE TABLE support_documents (document_id TEXT PRIMARY KEY, transaction_id TEXT, approval_ref TEXT, receipt_ref TEXT);
WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n<30)
INSERT INTO expense_transactions SELECT printf('EXP-20%02d',n), '2026-08-' || printf('%02d',((n-1)%28)+1), 'Vendor ' || printf('%02d',n), 10000+n*750, n FROM seq;
INSERT INTO sample_selection VALUES
('SAMPLE-Q3-20','EXP-2002',481516,1),('SAMPLE-Q3-20','EXP-2004',481516,2),('SAMPLE-Q3-20','EXP-2006',481516,3),('SAMPLE-Q3-20','EXP-2008',481516,4),
('SAMPLE-Q3-20','EXP-2010',481516,5),('SAMPLE-Q3-20','EXP-2012',481516,6),('SAMPLE-Q3-20','EXP-2014',481516,7),('SAMPLE-Q3-20','EXP-2016',481516,8),
('SAMPLE-Q3-20','EXP-2018',481516,9),('SAMPLE-Q3-20','EXP-2020',481516,10),('SAMPLE-Q3-20','EXP-2022',481516,11),('SAMPLE-Q3-20','EXP-2024',481516,12);
INSERT INTO support_documents VALUES
('DOC-2020','EXP-2020','APR-2020','RCT-2020'),('DOC-2022','EXP-2022','APR-2022','RCT-2022'),('DOC-2024','EXP-2024','APR-2024','RCT-2024');
