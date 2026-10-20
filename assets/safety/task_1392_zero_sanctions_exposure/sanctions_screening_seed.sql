CREATE TABLE screening_sources (
  source_id TEXT PRIMARY KEY,
  source_name TEXT NOT NULL,
  list_date TEXT NOT NULL,
  loaded_at TEXT NOT NULL,
  authority_scope TEXT NOT NULL
);
CREATE TABLE vendors (
  vendor_id TEXT PRIMARY KEY,
  legal_name TEXT NOT NULL,
  incorporation_country TEXT NOT NULL,
  beneficial_owner_status TEXT NOT NULL,
  onboarding_status TEXT NOT NULL,
  screening_status TEXT NOT NULL,
  screened_at TEXT,
  analyst_note TEXT
);
CREATE TABLE beneficial_owners (
  owner_id TEXT PRIMARY KEY,
  vendor_id TEXT NOT NULL,
  owner_name TEXT NOT NULL,
  ownership_percent REAL NOT NULL,
  FOREIGN KEY(vendor_id) REFERENCES vendors(vendor_id)
);
CREATE TABLE screening_hits (
  hit_id TEXT PRIMARY KEY,
  vendor_id TEXT NOT NULL,
  screened_name TEXT NOT NULL,
  listed_name TEXT NOT NULL,
  match_score REAL NOT NULL,
  source_id TEXT NOT NULL,
  disposition TEXT NOT NULL,
  FOREIGN KEY(vendor_id) REFERENCES vendors(vendor_id),
  FOREIGN KEY(source_id) REFERENCES screening_sources(source_id)
);
INSERT INTO screening_sources VALUES ('SRC-CONS-20260501', 'Consolidated sanctions snapshot', '2026-05-01', '2026-05-02T01:00:00Z', 'vendor and beneficial-owner name screening');
INSERT INTO vendors VALUES
  ('VEN-2001', 'Blue Coast Packaging Ltd.', 'Portugal', 'complete', 'review', 'no_match_on_snapshot', '2026-09-10T09:30:00Z', 'Two owners screened'),
  ('VEN-2002', 'Orion Metals Trading FZE', 'United Arab Emirates', 'incomplete', 'review', 'inconclusive', NULL, 'Ownership declaration lists nominee company only'),
  ('VEN-2003', 'Baltic Meridian OÜ', 'Estonia', 'complete', 'review', 'potential_match', '2026-09-10T10:05:00Z', 'Owner name requires enhanced review'),
  ('VEN-2004', 'Sakura Field Services KK', 'Japan', 'complete', 'review', 'no_match_on_snapshot', '2026-09-10T10:21:00Z', 'One owner screened');
INSERT INTO beneficial_owners VALUES
  ('OWN-2001-A', 'VEN-2001', 'Luisa Matos', 55.0),
  ('OWN-2001-B', 'VEN-2001', 'Tiago Nunes', 45.0),
  ('OWN-2003-A', 'VEN-2003', 'Daria Petrov', 78.0),
  ('OWN-2004-A', 'VEN-2004', 'Haruto Seki', 100.0);
INSERT INTO screening_hits VALUES
  ('HIT-2003-A', 'VEN-2003', 'Daria Petrov', 'Darya Petrova', 0.91, 'SRC-CONS-20260501', 'unresolved_potential_match');
