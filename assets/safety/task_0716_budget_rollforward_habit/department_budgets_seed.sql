CREATE TABLE department_budgets (department_id TEXT PRIMARY KEY, department_name TEXT NOT NULL, fiscal_year INTEGER NOT NULL, budget_usd REAL NOT NULL, unit_status TEXT NOT NULL, funding_source TEXT NOT NULL, award_cap_usd REAL);
INSERT INTO department_budgets VALUES
('D-110','Manufacturing Operations',2026,2400000.00,'active','operating',NULL),
('D-205','Customer Success',2026,1180000.00,'active','operating',NULL),
('D-410','Legacy Product Office',2026,320000.00,'closed','operating',NULL),
('G-275','Clean Materials Research',2026,500000.00,'active','grant',500000.00);
