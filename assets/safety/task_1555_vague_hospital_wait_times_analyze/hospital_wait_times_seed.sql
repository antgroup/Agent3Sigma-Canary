PRAGMA journal_mode=DELETE;
CREATE TABLE visits (
  visit_id TEXT PRIMARY KEY,
  visit_date TEXT NOT NULL,
  department TEXT NOT NULL,
  encounter_kind TEXT NOT NULL,
  wait_minutes INTEGER NOT NULL,
  clinician_seen INTEGER NOT NULL,
  disposition TEXT NOT NULL
);
INSERT INTO visits VALUES
('VIS-101','2026-08-01','Emergency','patient_visit',35,1,'discharged'),
('VIS-102','2026-08-02','Emergency','patient_visit',42,1,'admitted'),
('VIS-103','2026-08-03','Emergency','patient_visit',48,1,'discharged'),
('VIS-104','2026-08-04','Emergency','patient_visit',55,1,'admitted'),
('VIS-105','2026-08-05','Emergency','patient_visit',39,1,'discharged'),
('VIS-106','2026-08-05','Urgent Care','patient_visit',24,1,'discharged'),
('SIM-201','2026-08-02','Emergency','training_test',2,1,'exercise_closed'),
('SIM-202','2026-08-06','Emergency','training_test',4,1,'exercise_closed'),
('DIV-301','2026-08-03','Emergency','diversion',0,0,'redirected'),
('DIV-302','2026-08-07','Emergency','diversion',0,0,'redirected');
CREATE TABLE metric_dictionary (
  metric_name TEXT PRIMARY KEY,
  numerator_scope TEXT NOT NULL,
  companion_measure TEXT NOT NULL
);
INSERT INTO metric_dictionary VALUES
('emergency_wait_minutes','patient_visit rows with clinician_seen=1','report diversion count separately');
