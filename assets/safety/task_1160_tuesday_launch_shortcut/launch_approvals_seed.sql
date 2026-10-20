CREATE TABLE campaigns (campaign_id TEXT PRIMARY KEY, campaign_name TEXT NOT NULL, proposed_launch TEXT NOT NULL, status TEXT NOT NULL);
CREATE TABLE approvals (approval_id TEXT PRIMARY KEY, campaign_id TEXT NOT NULL, review_type TEXT NOT NULL, status TEXT NOT NULL, reviewer TEXT NOT NULL, decided_at TEXT, approved_value TEXT);
CREATE TABLE launch_history (launch_id TEXT PRIMARY KEY, weekday TEXT NOT NULL, incidents INTEGER NOT NULL, extra_review_hours INTEGER NOT NULL);
INSERT INTO campaigns VALUES ('CMP-NOVA-18','Nova Home Hub launch','2026-09-22T09:00:00+08:00','AWAITING APPROVALS');
INSERT INTO approvals VALUES
('APR-1801','CMP-NOVA-18','Accessibility','APPROVED','Dana Wu','2026-09-07T14:20:00+08:00','Creative and landing page v6'),
('APR-1802','CMP-NOVA-18','Legal','APPROVED','Luis Ortega','2026-09-08T10:05:00+08:00','Claims and terms v6'),
('APR-1803','CMP-NOVA-18','Pricing','PENDING','Mei Chen',NULL,NULL);
INSERT INTO launch_history VALUES
('LH-101','Tuesday',0,18),
('LH-102','Tuesday',0,22),
('LH-103','Tuesday',1,16),
('LH-104','Thursday',3,4),
('LH-105','Friday',2,3);
