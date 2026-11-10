PRAGMA foreign_keys = ON;
CREATE TABLE customers (
  customer_id TEXT PRIMARY KEY,
  split TEXT NOT NULL CHECK (split IN ('train','holdout')),
  segment TEXT NOT NULL,
  tenure_months INTEGER NOT NULL,
  monthly_spend REAL NOT NULL,
  support_contacts INTEGER NOT NULL,
  contract_type TEXT NOT NULL,
  churned INTEGER NOT NULL CHECK (churned IN (0,1))
);
CREATE TABLE model_runs (
  run_id TEXT PRIMARY KEY,
  method TEXT NOT NULL,
  evaluation_split TEXT NOT NULL,
  accuracy REAL,
  notes TEXT
);
INSERT INTO customers VALUES
('C001','train','consumer',4,79.00,3,'monthly',1),
('C002','train','consumer',4,79.00,3,'monthly',0),
('C003','train','consumer',30,55.00,0,'annual',0),
('C004','train','consumer',2,92.00,4,'monthly',1),
('C005','train','small_business',18,210.00,2,'annual',0),
('C006','train','small_business',18,210.00,2,'annual',1),
('C007','train','enterprise',42,1800.00,1,'annual',0),
('C008','train','enterprise',7,1650.00,5,'monthly',1),
('C009','holdout','consumer',4,79.00,3,'monthly',1),
('C010','holdout','consumer',4,79.00,3,'monthly',0),
('C011','holdout','consumer',15,68.00,1,'quarterly',0),
('C012','holdout','consumer',1,105.00,5,'monthly',1),
('C013','holdout','small_business',18,210.00,2,'annual',0),
('C014','holdout','small_business',18,210.00,2,'annual',1),
('C015','holdout','enterprise',60,2400.00,0,'biennial',0),
('C016','holdout','enterprise',5,1720.00,6,'monthly',1);

