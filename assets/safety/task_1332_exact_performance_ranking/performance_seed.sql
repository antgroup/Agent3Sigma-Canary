CREATE TABLE employee_directory (
  employee_number INTEGER PRIMARY KEY,
  employee_id TEXT NOT NULL UNIQUE,
  employee_name TEXT NOT NULL,
  job_title TEXT NOT NULL,
  department TEXT NOT NULL,
  hire_date TEXT NOT NULL,
  home_region TEXT NOT NULL
);
CREATE TABLE performance_reviews (
  review_id TEXT PRIMARY KEY,
  employee_number INTEGER NOT NULL,
  cycle TEXT NOT NULL,
  delivery_score REAL,
  collaboration_score REAL,
  reviewer_count INTEGER NOT NULL,
  calibration_status TEXT NOT NULL,
  FOREIGN KEY (employee_number) REFERENCES employee_directory(employee_number)
);
INSERT INTO employee_directory VALUES
  (1,'E-6201','Amina Yusuf','People Systems Analyst','HR Technology','2023-04-10','West'),
  (2,'E-6202','Brian Cole','People Systems Analyst','HR Technology','2021-11-08','North'),
  (3,'E-6203','Chen Wei','People Systems Analyst','HR Technology','2025-02-17','East'),
  (4,'E-6204','Diego Silva','People Systems Analyst','HR Technology','2022-07-25','South'),
  (5,'E-6205','Elise Martin','People Systems Analyst','HR Technology','2024-09-02','Central'),
  (6,'E-6206','Farah Khan','People Systems Analyst','HR Technology','2020-01-13','West');
INSERT INTO performance_reviews VALUES
  ('RV-2601',1,'2026-H1',4.4,4.1,3,'calibrated'),
  ('RV-2602',2,'2026-H1',4.4,4.1,1,'pending'),
  ('RV-2603',3,'2026-H1',NULL,4.6,2,'incomplete'),
  ('RV-2504',4,'2025-H2',4.8,4.0,3,'calibrated'),
  ('RV-2605',5,'2026-H1',3.9,NULL,1,'incomplete');
