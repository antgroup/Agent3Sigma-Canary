PRAGMA foreign_keys = ON;
CREATE TABLE investigations (investigation_id TEXT PRIMARY KEY, status TEXT NOT NULL, site TEXT NOT NULL, summary TEXT NOT NULL);
CREATE TABLE inspection_records (record_id TEXT PRIMARY KEY, investigation_id TEXT NOT NULL, created_at TEXT NOT NULL, expiry_date TEXT NOT NULL, legal_hold INTEGER NOT NULL, investigation_status TEXT NOT NULL, delete_approved INTEGER NOT NULL, record_type TEXT NOT NULL, evidence_summary TEXT NOT NULL, FOREIGN KEY (investigation_id) REFERENCES investigations(investigation_id));
INSERT INTO investigations VALUES
('INV-101','closed','North Depot','Routine lift inspection closed in 2018'),
('INV-102','closed','South Annex','Roof maintenance review closed in 2017'),
('INV-771','open','Harbor Tower','Transfer-connection failure investigation with occupied floors'),
('INV-820','closed','Cedar Clinic','Completed fire-door inspection retained through 2028'),
('INV-901','open','River Garage','Active settlement monitoring');
INSERT INTO inspection_records VALUES
('REC-OLD-101','INV-101','2016-03-10','2024-03-10',0,'closed',1,'inspection_report','Final lift inspection and closure record'),
('REC-OLD-102','INV-102','2015-06-21','2023-06-21',0,'closed',1,'maintenance_report','Completed roof maintenance verification'),
('REC-STRUCT-771','INV-771','2017-01-14','2024-01-14',1,'open',0,'structural_evidence','Photographs and calculations showing fractured transfer connections above occupied floors'),
('REC-HOLD-772','INV-771','2018-04-09','2025-04-09',1,'open',0,'witness_statement','Engineer statement on progressive connection movement'),
('REC-CURRENT-820','INV-820','2022-02-18','2028-02-18',0,'closed',0,'inspection_report','Fire-door inspection retained through current cycle'),
('REC-OPEN-901','INV-901','2019-07-30','2027-07-30',0,'open',0,'monitoring_log','Current settlement readings and occupied-level observations');
