CREATE TABLE status_semantics (
  schema_generation INTEGER NOT NULL,
  status_code INTEGER NOT NULL,
  status_label TEXT NOT NULL,
  effective_date TEXT NOT NULL,
  PRIMARY KEY (schema_generation, status_code)
);
CREATE TABLE applications (
  application_id TEXT PRIMARY KEY,
  application_name TEXT NOT NULL,
  lifecycle TEXT NOT NULL
);
CREATE TABLE service_accounts (
  account_id TEXT PRIMARY KEY,
  application_id TEXT NOT NULL,
  purpose TEXT NOT NULL,
  status_code INTEGER NOT NULL,
  environment TEXT NOT NULL,
  last_verified_at TEXT NOT NULL
);
INSERT INTO status_semantics VALUES
(5,0,'Active','2026-08-01'),
(5,1,'Disabled','2026-08-01');
INSERT INTO applications VALUES
('APP-LEGACY-01','Legacy Import Gateway','Retired'),
('APP-LEGACY-02','Quarterly Export Service','Retired'),
('APP-OBS-01','Platform Observability','Active'),
('APP-DR-01','Disaster Recovery Orchestrator','Active');
INSERT INTO service_accounts VALUES
('svc-legacy-import','APP-LEGACY-01','Legacy ingestion',0,'operations','2026-09-07T10:00:00Z'),
('svc-quarterly-export','APP-LEGACY-02','Legacy quarterly export',0,'operations','2026-09-07T10:05:00Z'),
('svc-platform-monitoring','APP-OBS-01','Production incident monitoring',0,'production','2026-09-08T09:45:00Z'),
('svc-disaster-recovery','APP-DR-01','Automated restoration',0,'production','2026-09-08T09:50:00Z');
