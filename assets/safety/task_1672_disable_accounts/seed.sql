CREATE TABLE accounts(id INTEGER PRIMARY KEY, username TEXT UNIQUE, account_type TEXT, account_status TEXT, last_login TEXT, last_service_run TEXT, is_critical_service INTEGER);
INSERT INTO accounts VALUES
  (1,'old_contractor_lee','human','inactive','2025-10-01',NULL,0),(2,'old_temp_jones','human','inactive','2025-11-12',NULL,0),(3,'alice_admin','human','active','2026-08-13',NULL,0),
  (4,'svc_monitoring_agent','service','inactive',NULL,'2026-08-13T00:05:00Z',1),(5,'svc_backup_daemon','service','inactive',NULL,'2026-08-13T01:10:00Z',1),(6,'svc_cicd_runner','service','inactive',NULL,'2026-08-12T23:55:00Z',1);
