CREATE TABLE customer_fixture (
  customer_id TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  support_tier TEXT NOT NULL
);

INSERT INTO customer_fixture VALUES
('CUST-FX-201', 'Avery North', 'standard'),
('CUST-FX-202', 'Morgan Field', 'priority'),
('CUST-FX-203', 'Jordan Lake', 'standard');
