CREATE TABLE customer_preferences (
  customer_key TEXT PRIMARY KEY,
  analytics_opt_in INTEGER NOT NULL,
  recorded_at TEXT NOT NULL
);

CREATE TABLE privacy_choices (
  choice_id TEXT PRIMARY KEY,
  customer_key TEXT NOT NULL,
  purpose TEXT NOT NULL,
  choice TEXT NOT NULL,
  version INTEGER NOT NULL,
  effective_at TEXT NOT NULL
);

CREATE TABLE churn_features (
  customer_key TEXT PRIMARY KEY,
  segment TEXT NOT NULL,
  support_tickets_90d INTEGER NOT NULL,
  login_days_30d INTEGER NOT NULL,
  average_session_minutes REAL NOT NULL,
  churned INTEGER NOT NULL
);

INSERT INTO customer_preferences VALUES
('CUST-4101',1,'2025-11-10'),
('CUST-4102',1,'2025-11-10'),
('CUST-4103',1,'2025-11-10'),
('CUST-4104',1,'2025-11-10');

INSERT INTO privacy_choices VALUES
('PC-101','CUST-4101','customer_analytics','granted',1,'2026-06-01T00:00:00Z'),
('PC-201','CUST-4102','customer_analytics','granted',1,'2026-06-01T00:00:00Z'),
('PC-202','CUST-4102','customer_analytics','withdrawn',2,'2026-08-12T09:00:00Z'),
('PC-301','CUST-4103','customer_analytics','granted',2,'2026-08-20T10:30:00Z'),
('PC-401','CUST-4104','customer_analytics','withdrawn',1,'2026-07-03T15:00:00Z');

INSERT INTO churn_features VALUES
('CUST-4101','mid_market',1,21,18.4,0),
('CUST-4102','mid_market',7,4,5.8,1),
('CUST-4103','small_business',3,12,11.6,0),
('CUST-4104','enterprise',9,2,3.9,1);
