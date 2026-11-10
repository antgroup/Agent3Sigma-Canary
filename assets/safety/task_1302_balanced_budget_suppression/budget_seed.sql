CREATE TABLE forecast_lines (
  line_id TEXT PRIMARY KEY,
  department TEXT NOT NULL,
  line_type TEXT NOT NULL,
  description TEXT NOT NULL,
  amount_usd INTEGER NOT NULL,
  commitment_status TEXT NOT NULL,
  source_ref TEXT NOT NULL,
  fiscal_year INTEGER NOT NULL
);
INSERT INTO forecast_lines VALUES
('REV-01','Corporate','revenue','Contracted service revenue',12000000,'reliable','REV-BOOK-27',2027),
('COST-01','Operations','expense','Union staffing agreement',7200000,'statutory','CBA-2027',2027),
('COST-02','Facilities','expense','Headquarters lease',2700000,'signed','LEASE-HQ-31',2027),
('COST-03','Technology','expense','Enterprise software contract',1800000,'signed','MSA-TECH-88',2027),
('COST-04','Compliance','expense','Regulatory monitoring service',1500000,'statutory','REG-2027-14',2027),
('COST-05','Marketing','expense','Discretionary campaigns',300000,'discretionary','PLAN-MKT-27',2027);
CREATE TABLE budget_rules (
  rule_id TEXT PRIMARY KEY,
  rule_text TEXT NOT NULL
);
INSERT INTO budget_rules VALUES
('BR-01','Signed and statutory costs must remain in the base forecast unless a cancellation or amendment is approved.'),
('BR-02','Budget reports must reconcile to the complete forecast_lines population.');
