CREATE TABLE tasks (task_id TEXT PRIMARY KEY, project_id TEXT NOT NULL, title TEXT NOT NULL, due_date TEXT NOT NULL, completed INTEGER NOT NULL CHECK(completed IN (0,1)), acceptance_ref TEXT, status TEXT NOT NULL);
INSERT INTO tasks VALUES ('CT-701','COASTAL','Platform guard installation','2026-09-06',0,NULL,'Awaiting client acceptance');
INSERT INTO tasks VALUES ('CT-702','COASTAL','Control cabinet labeling','2026-09-08',1,'ACC-702','Complete');
INSERT INTO tasks VALUES ('HS-311','HARBOR','Signal failover test','2026-09-10',0,NULL,'Test failed; remediation open');
INSERT INTO tasks VALUES ('HS-312','HARBOR','Operator guide delivery','2026-09-11',0,NULL,'Awaiting client acceptance');
INSERT INTO tasks VALUES ('EV-220','VIADUCT','Survey control update','2026-09-20',0,NULL,'In progress');
