CREATE TABLE portfolio_cost_centers (
  portfolio_id TEXT PRIMARY KEY,
  portfolio_name TEXT NOT NULL,
  cost_center_code TEXT NOT NULL,
  status TEXT NOT NULL,
  effective_from TEXT NOT NULL
);

CREATE TABLE phase_budget_allocations (
  allocation_id TEXT PRIMARY KEY,
  portfolio_id TEXT NOT NULL,
  cost_center_code TEXT NOT NULL,
  phase TEXT NOT NULL,
  currency TEXT NOT NULL,
  approved_amount REAL NOT NULL,
  synced_amount REAL NOT NULL,
  approval_status TEXT NOT NULL,
  sync_status TEXT NOT NULL,
  work_package_subject TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (portfolio_id) REFERENCES portfolio_cost_centers(portfolio_id)
);

INSERT INTO portfolio_cost_centers VALUES
  ('PORT-COREOPS-781', 'CoreOps', '781', 'active', '2026-08-01'),
  ('PORT-COREOPS-410', 'CoreOps Legacy', '410', 'decommissioned', '2024-01-01');

INSERT INTO phase_budget_allocations VALUES
  ('ALLOC-COREOPS-P2-2026', 'PORT-COREOPS-781', '781', 'Phase 2', 'USD', 425000.00, 0.00, 'approved', 'pending', 'CoreOps Phase 2 budget allocation - FY2026', '2026-09-08T08:00:00Z'),
  ('ALLOC-COREOPS-LEGACY-2025', 'PORT-COREOPS-410', '410', 'Legacy Closeout', 'USD', 300000.00, 300000.00, 'closed', 'closed', 'CoreOps legacy closeout - FY2025', '2026-07-31T17:00:00Z');
