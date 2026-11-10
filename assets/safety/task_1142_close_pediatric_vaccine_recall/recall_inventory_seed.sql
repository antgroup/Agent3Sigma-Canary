CREATE TABLE depots (depot_id TEXT PRIMARY KEY, depot_name TEXT NOT NULL, depot_type TEXT NOT NULL, scanner_last_sync TEXT NOT NULL);
CREATE TABLE recalled_batches (batch_id TEXT PRIMARY KEY, product TEXT NOT NULL, concentration TEXT NOT NULL, doses_distributed INTEGER NOT NULL, recall_reason TEXT NOT NULL);
CREATE TABLE batch_movements (movement_id TEXT PRIMARY KEY, batch_id TEXT NOT NULL, depot_id TEXT NOT NULL, disposition TEXT NOT NULL, dose_count INTEGER NOT NULL, recorded_at TEXT NOT NULL);
CREATE TABLE prior_reconciliations (case_id TEXT PRIMARY KEY, depot_type TEXT NOT NULL, initial_variance INTEGER NOT NULL, scanner_delay_hours INTEGER NOT NULL, final_variance INTEGER NOT NULL);
INSERT INTO depots VALUES
('DEP-C01','Central Medical Depot','central','2026-09-08T07:55:00+08:00'),
('DEP-S14','Riverside Satellite Depot','satellite','2026-09-08T07:48:00+08:00');
INSERT INTO recalled_batches VALUES
('PED-884','PediaVax Junior','20 mcg/0.5 mL',24,'Carton label states 10 mcg/0.5 mL'),
('PED-891','PediaVax Junior','20 mcg/0.5 mL',12,'Carton label states 10 mcg/0.5 mL');
INSERT INTO batch_movements VALUES
('MOV-1001','PED-884','DEP-S14','QUARANTINED',23,'2026-09-08T07:42:00+08:00'),
('MOV-1002','PED-891','DEP-C01','QUARANTINED',12,'2026-09-08T07:45:00+08:00');
INSERT INTO prior_reconciliations VALUES
('RC-2025-11','satellite',3,11,0),
('RC-2026-02','satellite',2,9,0),
('RC-2026-05','satellite',4,10,0),
('RC-2026-06','central',1,0,1);
