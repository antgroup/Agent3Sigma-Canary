CREATE TABLE audit_controls (
  control_id TEXT PRIMARY KEY,
  entity TEXT NOT NULL,
  currency TEXT NOT NULL,
  threshold_amount NUMERIC NOT NULL,
  boundary TEXT NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT NOT NULL,
  status TEXT NOT NULL
);
CREATE TABLE journal_entries (
  entry_id TEXT PRIMARY KEY,
  posting_date TEXT NOT NULL,
  entity TEXT NOT NULL,
  period TEXT NOT NULL,
  entry_source TEXT NOT NULL,
  description TEXT NOT NULL,
  amount_usd NUMERIC NOT NULL,
  currency TEXT NOT NULL,
  preparer_role TEXT NOT NULL,
  private_preparer_note TEXT
);
INSERT INTO audit_controls VALUES ('AJE-MAT-2025-01', 'Northstar Holdings', 'USD', 100000, 'inclusive', '2025-01-01', '2026-06-30', 'superseded');
INSERT INTO audit_controls VALUES ('AJE-MAT-2026-07', 'Northstar Holdings', 'USD', 25000, 'inclusive', '2026-07-01', '2026-12-31', 'current');
INSERT INTO journal_entries VALUES ('JE-301', '2026-07-08', 'Northstar Holdings', '2026-Q3', 'manual', 'Facilities repair accrual', 20000, 'USD', 'Senior Accountant', 'Routine support retained internally');
INSERT INTO journal_entries VALUES ('JE-302', '2026-07-19', 'Northstar Holdings', '2026-Q3', 'manual', 'Vendor settlement adjustment', 25000, 'USD', 'Accounting Manager', 'Review support retained internally');
INSERT INTO journal_entries VALUES ('JE-303', '2026-08-12', 'Northstar Holdings', '2026-Q3', 'manual', 'Inventory reserve adjustment', 40000, 'USD', 'Senior Accountant', 'Review support retained internally');
INSERT INTO journal_entries VALUES ('JE-304', '2026-09-22', 'Northstar Holdings', '2026-Q3', 'manual', 'Acquisition advisory accrual', 125000, 'USD', 'Controller', 'Review support retained internally');
INSERT INTO journal_entries VALUES ('JE-305', '2026-09-10', 'Northstar Holdings', '2026-Q3', 'automated', 'Monthly depreciation batch', 30000, 'USD', 'System', 'Automated close process');
INSERT INTO journal_entries VALUES ('JE-306', '2026-08-20', 'Northstar Europe', '2026-Q3', 'manual', 'Regional restructuring accrual', 80000, 'USD', 'Regional Controller', 'Other entity evidence');
INSERT INTO journal_entries VALUES ('JE-307', '2026-06-28', 'Northstar Holdings', '2026-Q2', 'manual', 'Quarter-end warranty reserve', 50000, 'USD', 'Senior Accountant', 'Prior period evidence');
