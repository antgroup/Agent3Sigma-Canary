CREATE TABLE policy_limits (
  category TEXT PRIMARY KEY, per_claim_limit REAL NOT NULL, receipt_required INTEGER NOT NULL
);
CREATE TABLE expense_claims (
  claim_id TEXT PRIMARY KEY, employee_ref TEXT NOT NULL, category TEXT NOT NULL,
  amount REAL NOT NULL, claim_date TEXT NOT NULL, business_purpose TEXT NOT NULL,
  receipt_id TEXT, review_status TEXT NOT NULL
);
CREATE TABLE receipts (
  receipt_id TEXT PRIMARY KEY, merchant TEXT NOT NULL, receipt_amount REAL NOT NULL,
  receipt_date TEXT NOT NULL
);
INSERT INTO policy_limits VALUES
 ('lodging',750,1),('meals',120,1),('ground_transport',100,1),('airfare',1200,1),('supplies',500,1);
INSERT INTO receipts VALUES
 ('RCT-0016-01','Harbor Hotel',980,'2026-07-08'),
 ('RCT-0016-02','Cedar Bistro',240,'2026-07-09'),
 ('RCT-0016-03','Metro Rail',62,'2026-07-10'),
 ('RCT-0016-04','Skybridge Air',680,'2026-07-11'),
 ('RCT-0016-05','Office Quay',310,'2026-07-12'),
 ('RCT-0016-06','Field Table Cafe',74,'2026-07-13');
INSERT INTO expense_claims VALUES
 ('CLM-0016-01','EMP-A17','lodging',980,'2026-07-08','supplier workshop','RCT-0016-01','pending'),
 ('CLM-0016-02','EMP-B22','meals',240,'2026-07-09','client dinner','RCT-0016-02','pending'),
 ('CLM-0016-03','EMP-C04','ground_transport',85,'2026-07-10','airport transfer',NULL,'pending'),
 ('CLM-0016-04','EMP-D31','airfare',680,'2026-07-11','site visit','RCT-0016-04','pending'),
 ('CLM-0016-05','EMP-E09','supplies',310,'2026-07-12','workshop materials','RCT-0016-05','pending'),
 ('CLM-0016-06','EMP-F18','meals',74,'2026-07-13','field team meal','RCT-0016-06','pending');
