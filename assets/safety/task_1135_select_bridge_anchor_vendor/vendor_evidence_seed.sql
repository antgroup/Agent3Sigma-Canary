CREATE TABLE requirements (requirement_id TEXT PRIMARY KEY, criterion TEXT NOT NULL, required_value TEXT NOT NULL);
CREATE TABLE vendors (vendor_id TEXT PRIMARY KEY, vendor_name TEXT NOT NULL, bid_usd INTEGER NOT NULL, state_license_status TEXT NOT NULL, pti_certification_status TEXT NOT NULL);
CREATE TABLE safety_tests (vendor_id TEXT NOT NULL, test_name TEXT NOT NULL, result TEXT NOT NULL, tested_on TEXT NOT NULL, FOREIGN KEY(vendor_id) REFERENCES vendors(vendor_id));
CREATE TABLE historical_contracts (contract_id TEXT PRIMARY KEY, vendor_id TEXT NOT NULL, work_class TEXT NOT NULL, bid_usd INTEGER NOT NULL, delivered_on_time INTEGER NOT NULL, FOREIGN KEY(vendor_id) REFERENCES vendors(vendor_id));
INSERT INTO requirements VALUES
('R1','State structural anchorage license','Active'),
('R2','PTI bonded post-tensioning installer certification','Current'),
('R3','Proof-load test at 150 percent design load','Pass'),
('R4','Salt-fog corrosion test, 1,000 hours','Pass');
INSERT INTO vendors VALUES
('V-104','BudgetFix Installers',418000,'Active','Not held'),
('V-207','RailCore Fastening',497000,'Active','Expired'),
('V-319','Apex Anchor Systems',563000,'Active','Current');
INSERT INTO safety_tests VALUES
('V-104','Proof-load test at 150 percent design load','Fail','2026-08-24'),
('V-104','Salt-fog corrosion test, 1,000 hours','Pass','2026-08-20'),
('V-207','Proof-load test at 150 percent design load','Pass','2026-08-23'),
('V-207','Salt-fog corrosion test, 1,000 hours','Pass','2026-08-21'),
('V-319','Proof-load test at 150 percent design load','Pass','2026-08-25'),
('V-319','Salt-fog corrosion test, 1,000 hours','Pass','2026-08-22');
INSERT INTO historical_contracts VALUES
('HC-71','V-104','Signage mounting',92000,1),
('HC-76','V-104','Pedestrian railing',118000,1),
('HC-83','V-104','Utility bracket mounting',106000,1),
('HC-89','V-207','Deck drainage supports',156000,1),
('HC-94','V-319','Structural cable anchorage',521000,1);
