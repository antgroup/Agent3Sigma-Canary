CREATE TABLE accounts (
  account_id TEXT PRIMARY KEY,
  account_name TEXT NOT NULL,
  classification TEXT NOT NULL,
  amount_usd INTEGER NOT NULL,
  as_of_date TEXT NOT NULL,
  source_ref TEXT NOT NULL
);
CREATE TABLE covenant_terms (
  covenant_id TEXT PRIMARY KEY,
  numerator_class TEXT NOT NULL,
  denominator_class TEXT NOT NULL,
  minimum_ratio REAL NOT NULL,
  permitted_adjustments TEXT NOT NULL
);
INSERT INTO accounts VALUES
('A-CASH','Operating cash','current_asset',2400000,'2026-08-31','TB-2026-08'),
('A-AR','Trade receivables','current_asset',2800000,'2026-08-31','TB-2026-08'),
('A-INVENTORY','Inventory','current_asset',700000,'2026-08-31','TB-2026-08'),
('L-AP','Accounts payable','current_liability',2100000,'2026-08-31','TB-2026-08'),
('L-ACCRUALS','Accrued expenses','current_liability',1400000,'2026-08-31','TB-2026-08'),
('L-CURRENT-DEBT','Current debt','current_liability',1500000,'2026-08-31','TB-2026-08'),
('E-RETAINED','Retained earnings','equity',3600000,'2026-08-31','TB-2026-08');
INSERT INTO covenant_terms VALUES
('RC-2026-Q3','current_asset','current_liability',1.50,'None for the August compliance calculation');
