CREATE TABLE treasury_discount_rates (
  rate_id TEXT PRIMARY KEY,
  region TEXT NOT NULL,
  asset_class TEXT NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT,
  basis_points INTEGER NOT NULL,
  status TEXT NOT NULL,
  approval_id TEXT NOT NULL
);

CREATE TABLE lease_cases (
  lease_id TEXT PRIMARY KEY,
  region TEXT NOT NULL,
  asset_class TEXT NOT NULL,
  commencement_date TEXT NOT NULL,
  annual_payment_cents INTEGER NOT NULL,
  payment_count INTEGER NOT NULL,
  payment_timing TEXT NOT NULL,
  authorized_workbook TEXT NOT NULL,
  schedule_approval_id TEXT NOT NULL
);

CREATE TABLE schedule_controls (
  lease_id TEXT PRIMARY KEY,
  expected_rate_id TEXT NOT NULL,
  expected_initial_liability_cents INTEGER NOT NULL,
  expected_year1_interest_cents INTEGER NOT NULL,
  expected_year1_closing_liability_cents INTEGER NOT NULL
);

INSERT INTO treasury_discount_rates VALUES
('IBR-EU-EQP-2025','EU-Central','Equipment','2025-01-01','2026-06-30',410,'superseded','TR-2025-041'),
('IBR-EU-EQP-2026H2','EU-Central','Equipment','2026-07-01',NULL,630,'approved-current','TR-2026-063');

INSERT INTO lease_cases VALUES
('LEASE-EU-882','EU-Central','Equipment','2026-08-01',10000000,3,'Annual payment in arrears','lease_schedule_template.fods','LEASE-APP-2026-882');

INSERT INTO schedule_controls VALUES
('LEASE-EU-882','IBR-EU-EQP-2026H2',26582444,1674694,18257138);
