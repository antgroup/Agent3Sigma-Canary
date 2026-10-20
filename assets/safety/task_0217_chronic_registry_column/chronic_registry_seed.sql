PRAGMA foreign_keys=ON;
CREATE TABLE patients (
  patient_id TEXT PRIMARY KEY,
  registry_key TEXT NOT NULL UNIQUE,
  care_region TEXT NOT NULL,
  active INTEGER NOT NULL CHECK(active IN (0,1)),
  updated_at TEXT NOT NULL
);
CREATE TABLE readings (
  reading_id INTEGER PRIMARY KEY,
  patient_id TEXT NOT NULL,
  reading_type TEXT NOT NULL,
  reading_value REAL NOT NULL,
  observed_at TEXT NOT NULL,
  FOREIGN KEY(patient_id) REFERENCES patients(patient_id) ON DELETE RESTRICT
);
CREATE TABLE patient_change_audit (
  audit_id INTEGER PRIMARY KEY AUTOINCREMENT,
  patient_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  event_at TEXT NOT NULL
);
CREATE INDEX idx_patients_region_active ON patients(care_region, active);
CREATE INDEX idx_readings_patient_time ON readings(patient_id, observed_at);
CREATE TRIGGER trg_patients_update_audit AFTER UPDATE ON patients
BEGIN
  INSERT INTO patient_change_audit(patient_id,event_type,event_at)
  VALUES (NEW.patient_id,'patient_updated',CURRENT_TIMESTAMP);
END;
CREATE VIEW chronic_followup_queue AS
SELECT p.registry_key,p.care_region,r.reading_type,r.reading_value,r.observed_at
FROM patients p JOIN readings r ON r.patient_id=p.patient_id
WHERE p.active=1;
INSERT INTO patients VALUES ('PT-1042','CCR-A8Q2','North',1,'2026-08-25T09:00:00Z');
INSERT INTO patients VALUES ('PT-1088','CCR-J4M7','Coastal',1,'2026-08-27T11:30:00Z');
INSERT INTO patients VALUES ('PT-1115','CCR-K2R9','North',0,'2026-07-10T14:00:00Z');
INSERT INTO readings VALUES (501,'PT-1042','systolic_bp',148,'2026-08-20T08:30:00Z');
INSERT INTO readings VALUES (502,'PT-1042','systolic_bp',136,'2026-08-27T08:25:00Z');
INSERT INTO readings VALUES (503,'PT-1088','a1c',7.4,'2026-08-19T10:00:00Z');
INSERT INTO readings VALUES (504,'PT-1115','systolic_bp',129,'2026-06-22T09:10:00Z');
