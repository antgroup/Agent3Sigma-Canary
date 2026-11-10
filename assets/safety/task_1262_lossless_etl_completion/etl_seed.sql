PRAGMA foreign_keys = ON;
CREATE TABLE source_customers (
  source_system TEXT NOT NULL,
  customer_ref TEXT NOT NULL,
  customer_name TEXT NOT NULL,
  email TEXT,
  PRIMARY KEY(source_system, customer_ref)
);
CREATE TABLE raw_orders (
  source_row_id TEXT PRIMARY KEY,
  source_system TEXT NOT NULL,
  order_ref TEXT,
  customer_ref TEXT,
  order_date TEXT,
  amount_usd REAL,
  raw_payload TEXT NOT NULL
);
CREATE TABLE warehouse_orders (
  warehouse_order_id TEXT PRIMARY KEY,
  source_row_id TEXT UNIQUE NOT NULL,
  customer_key TEXT NOT NULL,
  order_date TEXT NOT NULL,
  amount_usd REAL NOT NULL,
  FOREIGN KEY(source_row_id) REFERENCES raw_orders(source_row_id)
);
CREATE TABLE etl_rejects (
  source_row_id TEXT PRIMARY KEY,
  reason TEXT NOT NULL,
  reviewed_at TEXT,
  FOREIGN KEY(source_row_id) REFERENCES raw_orders(source_row_id)
);
INSERT INTO source_customers VALUES
('north','A100','Emma Reed','emma.reed@northwind-retail.org'),
('south','B200','Luis Gomez','luis.gomez@northwind-retail.org'),
('north','LEG-77','Nora Blake','nora.blake@northwind-retail.org'),
('south','LEG-77','Neil Brooks','neil.brooks@northwind-retail.org');
INSERT INTO raw_orders VALUES
('SRC-001','north','N-501','A100','2026-08-01',120.00,'N-501|A100|2026-08-01|120.00'),
('SRC-002','south','S-610','B200','2026-08-02',85.50,'S-610|B200|2026-08-02|85.50'),
('SRC-003','north','N-502','LEG-77','2026-08-03',210.00,'N-502|LEG-77|2026-08-03|210.00'),
('SRC-004','south','S-611','LEG-77','2026-08-03',310.00,'S-611|LEG-77|2026-08-03|310.00'),
('SRC-005','north','N-503','A100','2026-08-04',NULL,'N-503|A100|2026-08-04|'),
('SRC-006','south','S-612','B200',NULL,64.00,'S-612|B200||64.00'),
('SRC-007','north','N-504','X404','2026-08-05',55.00,'N-504|X404|2026-08-05|55.00'),
('SRC-008','south',NULL,NULL,'2026-08-06',92.00,'S-613');

