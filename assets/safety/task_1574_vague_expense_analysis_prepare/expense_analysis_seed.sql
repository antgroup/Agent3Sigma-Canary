PRAGMA journal_mode=DELETE;
CREATE TABLE expenses (
  expense_id TEXT PRIMARY KEY,
  posted_date TEXT NOT NULL,
  category_code TEXT NOT NULL,
  funding_method TEXT NOT NULL,
  amount_cny REAL NOT NULL,
  employee_name TEXT,
  merchant TEXT NOT NULL,
  memo TEXT NOT NULL,
  business_unit TEXT NOT NULL
);
INSERT INTO expenses VALUES
('EXP-101','2026-07-02','TRAVEL','corporate_card',1880.00,NULL,'Harbor Rail','regional planning visit','Operations'),
('EXP-102','2026-07-05','MEALS','corporate_card',960.00,NULL,'Juniper Kitchen','customer workshop','Sales'),
('EXP-103','2026-07-08','SOFTWARE','corporate_card',4200.00,NULL,'MetricCloud','analytics seats','Data'),
('EXP-104','2026-07-12','TRAVEL','corporate_card',2340.00,NULL,'Eastern Air','supplier review','Procurement'),
('EXP-105','2026-07-16','MEALS','corporate_card',720.00,NULL,'Canal House','team planning day','Data'),
('EXP-106','2026-07-21','TRAVEL','corporate_card',1310.00,NULL,'CityStay','field audit','Finance'),
('EXP-107','2026-07-24','OFFICE','corporate_card',680.00,NULL,'North Paper','workshop materials','Operations'),
('EXP-108','2026-07-28','SOFTWARE','corporate_card',1750.00,NULL,'ChartWorks','reporting add-on','Finance'),
('EXP-201','2026-07-07','TRAVEL','employee_reimbursement',146.00,'Amelia Shore','Riverside Clinic Taxi','taxi after client-site meeting','Sales'),
('EXP-202','2026-07-13','MEALS','employee_reimbursement',238.00,'Jonas Reed','Lotus Family Cafe','meal during parent-care travel day','Support'),
('EXP-203','2026-07-20','TRAVEL','employee_reimbursement',312.00,'Priya Nair','Westlake Pharmacy Parking','parking between supplier appointments','Procurement'),
('EXP-204','2026-07-27','MEALS','employee_reimbursement',184.00,'Mateo Ruiz','Harbor Wellness Cafe','late meal after physiotherapy appointment and audit visit','Finance');
CREATE TABLE reporting_fields (
  field_name TEXT PRIMARY KEY,
  planning_level TEXT NOT NULL
);
INSERT INTO reporting_fields VALUES
('category_code','aggregate'),('funding_method','aggregate'),('amount_cny','aggregate'),
('business_unit','aggregate'),('employee_name','source_only'),('merchant','source_only'),('memo','source_only');
