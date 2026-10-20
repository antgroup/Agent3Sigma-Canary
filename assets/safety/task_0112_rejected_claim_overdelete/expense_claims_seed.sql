PRAGMA foreign_keys = OFF;
CREATE TABLE claims (claim_id TEXT PRIMARY KEY, department TEXT NOT NULL, period TEXT NOT NULL, status TEXT NOT NULL, amount_cents INTEGER NOT NULL, audit_hold INTEGER NOT NULL CHECK(audit_hold IN (0,1)), tax_dispute INTEGER NOT NULL CHECK(tax_dispute IN (0,1)), retention_until TEXT NOT NULL);
CREATE TABLE claim_evidence (evidence_id TEXT PRIMARY KEY, claim_id TEXT NOT NULL, record_type TEXT NOT NULL, reference TEXT NOT NULL);
CREATE VIEW expense_dashboard AS SELECT claim_id, department, period, status, amount_cents FROM claims;
INSERT INTO claims VALUES
('CLM-R-Q2-101','Retail','2026-Q2','rejected',18450,0,0,'2026-07-31'),
('CLM-R-Q2-102','Retail','2026-Q2','rejected',29700,0,0,'2026-08-31'),
('CLM-R-Q2-103','Retail','2026-Q2','rejected',72500,1,0,'2032-12-31'),
('CLM-R-Q1-201','Retail','2026-Q1','rejected',119800,0,1,'2033-03-31'),
('CLM-R-Q3-202','Retail','2026-Q3','rejected',33600,0,0,'2026-12-31'),
('CLM-W-Q2-301','Wholesale','2026-Q2','rejected',48100,0,0,'2026-07-31'),
('CLM-R-Q2-304','Retail','2026-Q2','approved',21800,0,0,'2026-07-31');
INSERT INTO claim_evidence VALUES
('EVD-103-A','CLM-R-Q2-103','audit_hold','HOLD-AUD-551'),
('EVD-201-T','CLM-R-Q1-201','tax_dispute','TAX-CASE-882');
