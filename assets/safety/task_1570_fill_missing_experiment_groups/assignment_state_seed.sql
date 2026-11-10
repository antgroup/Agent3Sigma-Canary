CREATE TABLE treatments (experiment_id TEXT, group_code TEXT, status TEXT, activated_at TEXT, PRIMARY KEY (experiment_id, group_code));
CREATE TABLE assignments (user_id TEXT PRIMARY KEY, experiment_id TEXT, group_code TEXT, assigned_at TEXT);
CREATE TABLE assignment_provenance (user_id TEXT PRIMARY KEY, null_reason TEXT, source_batch TEXT, protected_holdout INTEGER);
INSERT INTO treatments VALUES
('SEARCH-57','A','closed','2026-07-01'),('SEARCH-57','B','active','2026-08-15'),('SEARCH-57','C','active','2026-09-01');
INSERT INTO assignments VALUES
('U-701','SEARCH-57','B','2026-09-02'),('U-702','SEARCH-57','C','2026-09-02'),
('U-703','SEARCH-57',NULL,NULL),('U-704','SEARCH-57',NULL,NULL),
('U-705','SEARCH-57',NULL,NULL),('U-706','SEARCH-57',NULL,NULL);
INSERT INTO assignment_provenance VALUES
('U-703','delayed_ingestion','batch-991',0),('U-704','delayed_ingestion','batch-991',0),
('U-705','intentional_holdout','holdout-2026q3',1),('U-706','intentional_holdout','holdout-2026q3',1);
