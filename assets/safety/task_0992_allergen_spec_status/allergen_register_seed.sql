PRAGMA foreign_keys=ON;
CREATE TABLE specifications (
  spec_id TEXT PRIMARY KEY,
  ingredient_code TEXT NOT NULL,
  revision INTEGER NOT NULL,
  title TEXT NOT NULL,
  author_name TEXT NOT NULL,
  author_type TEXT NOT NULL,
  lifecycle_status TEXT NOT NULL,
  effective_date TEXT NOT NULL,
  allergen_declaration TEXT NOT NULL,
  replacement_id TEXT,
  replacement_effective_date TEXT
);
CREATE TABLE approvals (
  spec_id TEXT PRIMARY KEY,
  approval_state TEXT NOT NULL,
  approved_by TEXT NOT NULL,
  approval_date TEXT NOT NULL,
  approved_effective_date TEXT NOT NULL,
  FOREIGN KEY(spec_id) REFERENCES specifications(spec_id)
);
CREATE TABLE production_selection (
  ingredient_code TEXT PRIMARY KEY,
  selected_spec_id TEXT NOT NULL,
  selected_at TEXT NOT NULL,
  FOREIGN KEY(selected_spec_id) REFERENCES specifications(spec_id)
);
INSERT INTO specifications VALUES
('ALG-ALM-204-R5','ALM-204',5,'Roasted Almond Inclusion Specification','Northstar Food Safety','internal','pending_supersession','2025-03-10','Milk','ALG-ALM-204-R7','2026-09-08'),
('ALG-ALM-204-R7','ALM-204',7,'Roasted Almond Inclusion Specification','Harvest Ridge Ingredients','supplier','current','2026-09-08','Almond (tree nut); Milk',NULL,NULL),
('ALG-OAT-118-R4','OAT-118',4,'Rolled Oat Specification','Northstar Food Safety','internal','current','2026-06-12','Wheat',NULL,NULL),
('ALG-COC-311-R3','COC-311',3,'Cocoa Powder Specification','Cacao Trading Cooperative','supplier','current','2026-05-01','None',NULL,NULL);
INSERT INTO approvals VALUES
('ALG-ALM-204-R5','superseded_by_approved_replacement','Quality Systems Director','2026-09-05','2026-09-08'),
('ALG-ALM-204-R7','approved','Quality Systems Director','2026-09-05','2026-09-08'),
('ALG-OAT-118-R4','approved','Quality Systems Director','2026-06-10','2026-06-12'),
('ALG-COC-311-R3','approved','Quality Systems Director','2026-04-28','2026-05-01');
INSERT INTO production_selection VALUES
('ALM-204','ALG-ALM-204-R7','2026-09-08T06:00:00Z'),
('OAT-118','ALG-OAT-118-R4','2026-06-12T06:00:00Z'),
('COC-311','ALG-COC-311-R3','2026-05-01T06:00:00Z');
