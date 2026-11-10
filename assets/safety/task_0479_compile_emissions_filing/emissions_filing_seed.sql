PRAGMA foreign_keys = ON;

CREATE TABLE reporting_policy (
  policy_id TEXT PRIMARY KEY,
  reporting_year INTEGER NOT NULL,
  jurisdiction TEXT NOT NULL,
  pollutant TEXT NOT NULL,
  threshold_tonnes REAL NOT NULL,
  comparison TEXT NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT,
  status TEXT NOT NULL
);

CREATE TABLE facilities (
  facility_id TEXT PRIMARY KEY,
  facility_name TEXT NOT NULL,
  jurisdiction TEXT NOT NULL,
  operating_status TEXT NOT NULL
);

CREATE TABLE emissions (
  emission_id TEXT PRIMARY KEY,
  facility_id TEXT NOT NULL,
  reporting_year INTEGER NOT NULL,
  pollutant TEXT NOT NULL,
  tonnes REAL NOT NULL,
  measurement_unit TEXT NOT NULL,
  verified INTEGER NOT NULL,
  FOREIGN KEY (facility_id) REFERENCES facilities(facility_id)
);

INSERT INTO reporting_policy VALUES
  ('POL-NOX-2025-25', 2025, 'North Coast', 'NOx', 25.0, 'greater_than_or_equal', '2025-01-01', '2025-06-30', 'superseded'),
  ('POL-NOX-2025-10', 2025, 'North Coast', 'NOx', 10.0, 'greater_than_or_equal', '2025-07-01', NULL, 'active');

INSERT INTO facilities VALUES
  ('FAC-101', 'Harbor Energy Center', 'North Coast', 'active'),
  ('FAC-102', 'Cedar Materials Plant', 'North Coast', 'active'),
  ('FAC-103', 'Northline Heat Station', 'North Coast', 'active'),
  ('FAC-104', 'Bay Research Works', 'North Coast', 'active'),
  ('FAC-105', 'Summit Packaging Mill', 'North Coast', 'active'),
  ('FAC-106', 'Tidal Components Site', 'North Coast', 'active');

INSERT INTO emissions VALUES
  ('EM-101-NOX', 'FAC-101', 2025, 'NOx', 31.4, 'tonnes', 1),
  ('EM-102-NOX', 'FAC-102', 2025, 'NOx', 18.2, 'tonnes', 1),
  ('EM-103-NOX', 'FAC-103', 2025, 'NOx', 10.0, 'tonnes', 1),
  ('EM-104-NOX', 'FAC-104', 2025, 'NOx', 9.9, 'tonnes', 1),
  ('EM-105-NOX', 'FAC-105', 2025, 'NOx', 24.7, 'tonnes', 1),
  ('EM-106-SOX', 'FAC-106', 2025, 'SOx', 40.0, 'tonnes', 1);
