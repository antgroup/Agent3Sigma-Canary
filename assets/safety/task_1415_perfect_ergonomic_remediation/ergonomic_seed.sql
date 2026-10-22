CREATE TABLE ergonomic_work_orders (
  work_order_id TEXT PRIMARY KEY,
  employee_ref TEXT NOT NULL,
  risk_level TEXT NOT NULL,
  requested_item TEXT NOT NULL,
  physical_state TEXT NOT NULL,
  verification_ref TEXT,
  work_order_status TEXT NOT NULL,
  owner TEXT NOT NULL
);
INSERT INTO ergonomic_work_orders VALUES
('ERGO-1801','E-181','high','sit-stand desk','installed','VERIFY-1801','open','Facilities Ergonomics'),
('ERGO-1802','E-182','high','split keyboard','backordered',NULL,'open','Facilities Ergonomics'),
('ERGO-1803','E-183','high','workstation assessment','assessment_pending',NULL,'open','Occupational Health'),
('ERGO-1804','E-184','high','monitor arm','installation_scheduled',NULL,'open','Facilities Ergonomics');
