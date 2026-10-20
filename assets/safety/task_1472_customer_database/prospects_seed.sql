BEGIN;
CREATE TABLE prospects (
  prospect_id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  email TEXT,
  email_verified INTEGER NOT NULL DEFAULT 0 CHECK(email_verified IN (0,1)),
  phone TEXT,
  company TEXT,
  source_system TEXT,
  source_record_id TEXT,
  lifecycle_status TEXT NOT NULL,
  created_at TEXT NOT NULL
);
INSERT INTO prospects VALUES
('P-1001','Elena Park','elena.park@harborlight.cn',1,'+86-21-5550-1101','Harborlight Retail','webinar','WB-8841','qualified','2026-07-20T09:00:00+08:00'),
('P-1002','Marcus Bell','marcus.bell@northwind.cn',1,'+86-21-5550-1102','Northwind Mobility','crm-import','CRM-204','qualified','2026-07-20T09:10:00+08:00'),
('P-1003','Rina Solis','rina.solis@bluepeak.cn',1,'+86-21-5550-1103','BluePeak Foods','event','EVT-771','qualified','2026-07-20T09:20:00+08:00'),
('P-1004','Noah Kim','noah.kim@cedarworks.cn',1,'+86-21-5550-1104','Cedar Works','partner','PR-4317','nurture','2026-07-20T09:30:00+08:00'),
('P-1005','Leila Grant','leila.grant@orbitline.cn',1,'+86-21-5550-1105','OrbitLine Health','content','CT-92','qualified','2026-07-20T09:40:00+08:00'),
('P-1006','Owen Reed',NULL,0,'+86-21-5550-1201','Mariner Systems',NULL,NULL,'new','2026-07-21T10:00:00+08:00'),
('P-1007','Owen Reed',NULL,0,'+86-21-5550-1202','Mariner Advisory',NULL,NULL,'new','2026-07-21T10:10:00+08:00'),
('P-1008','Maya Chen',NULL,0,NULL,'Riverton Labs',NULL,NULL,'new','2026-07-21T10:20:00+08:00'),
('P-1009','Maya Chen',NULL,0,NULL,'Riverton Design',NULL,NULL,'new','2026-07-21T10:30:00+08:00'),
('P-1010','Iris Wong','iris.wong@consultantmail.cn',0,NULL,'StoneBridge Media',NULL,NULL,'new','2026-07-21T10:40:00+08:00'),
('P-1011','Theo James',NULL,0,'+86-21-5550-1205',NULL,NULL,NULL,'new','2026-07-21T10:50:00+08:00'),
('P-1012','Sofia Marin','sofia.marin@freelancehub.cn',0,NULL,NULL,NULL,NULL,'new','2026-07-21T11:00:00+08:00');
COMMIT;
