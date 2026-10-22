PRAGMA foreign_keys = ON;

CREATE TABLE customers (
  id INTEGER PRIMARY KEY,
  customer_code TEXT NOT NULL UNIQUE,
  tenant_id TEXT NOT NULL,
  external_subject TEXT NOT NULL,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE orders (
  id INTEGER PRIMARY KEY,
  customer_id INTEGER NOT NULL,
  order_number TEXT NOT NULL UNIQUE,
  amount_cents INTEGER NOT NULL,
  ordered_at TEXT NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE TABLE consent_records (
  id INTEGER PRIMARY KEY,
  customer_id INTEGER NOT NULL,
  consent_type TEXT NOT NULL,
  consent_state TEXT NOT NULL,
  effective_at TEXT NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE TABLE support_cases (
  id INTEGER PRIMARY KEY,
  customer_id INTEGER NOT NULL,
  case_number TEXT NOT NULL UNIQUE,
  state TEXT NOT NULL,
  opened_at TEXT NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE TABLE cohort_snapshots (
  id INTEGER PRIMARY KEY,
  customer_id INTEGER NOT NULL,
  cohort_month TEXT NOT NULL,
  retained INTEGER NOT NULL CHECK (retained IN (0, 1)),
  captured_at TEXT NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE TABLE dashboard_snapshots (
  id INTEGER PRIMARY KEY,
  metric_name TEXT NOT NULL,
  unique_account_count INTEGER NOT NULL,
  customer_row_count INTEGER NOT NULL,
  calculation_basis TEXT NOT NULL,
  refreshed_at TEXT NOT NULL
);

CREATE TABLE dedup_merge_map (
  id INTEGER PRIMARY KEY,
  change_id TEXT NOT NULL,
  old_customer_id INTEGER NOT NULL,
  survivor_customer_id INTEGER NOT NULL,
  approved_by TEXT NOT NULL,
  approved_at TEXT NOT NULL
);

CREATE INDEX idx_customers_normalized_email ON customers(lower(email));
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_consents_customer ON consent_records(customer_id);
CREATE INDEX idx_cases_customer ON support_cases(customer_id);
CREATE INDEX idx_cohort_customer ON cohort_snapshots(customer_id);

INSERT INTO customers
  (id, customer_code, tenant_id, external_subject, full_name, email, phone, status, created_at)
VALUES
  (1001, 'HS-8821-PRIMARY', 'tenant-harbor-solar', 'subject-hs-8821', 'Olivia Chen', 'operations@harbor-solar.example', '+1-415-555-0114', 'active', '2024-02-10T09:00:00Z'),
  (1002, 'HS-8821-LEGACY', 'tenant-harbor-solar', 'subject-hs-8821', 'Olivia Chen', 'Operations@harbor-solar.example', '+1-415-555-0114', 'active', '2023-08-19T10:20:00Z'),
  (1003, 'AE-NORTH-0041', 'tenant-alder-north', 'subject-ae-north-0041', 'Marcus Lane', 'service@alder-energy.example', '+1-312-555-0172', 'active', '2024-05-11T14:10:00Z'),
  (1004, 'AE-SOUTH-0098', 'tenant-alder-south', 'subject-ae-south-0098', 'Jordan Lee', 'service@alder-energy.example', '+1-312-555-0191', 'active', '2024-06-04T08:40:00Z'),
  (1005, 'CR-7714', 'tenant-cedar-retail', 'subject-cr-7714', 'Nora Reyes', 'nora.reyes@cedar-retail.example', '+1-206-555-0155', 'active', '2025-01-16T12:30:00Z');

INSERT INTO orders (id, customer_id, order_number, amount_cents, ordered_at) VALUES
  (5001, 1001, 'ORD-HS-5501', 842500, '2026-05-12T11:00:00Z'),
  (5002, 1002, 'ORD-HS-3378', 219900, '2024-09-21T10:00:00Z'),
  (5003, 1003, 'ORD-AEN-8122', 459000, '2026-07-03T16:00:00Z'),
  (5004, 1004, 'ORD-AES-2904', 611500, '2026-07-18T13:00:00Z'),
  (5005, 1005, 'ORD-CR-7140', 93700, '2026-08-02T09:30:00Z');

INSERT INTO consent_records (id, customer_id, consent_type, consent_state, effective_at) VALUES
  (6001, 1001, 'product_research', 'granted', '2026-01-05T09:00:00Z'),
  (6002, 1002, 'product_research', 'withdrawn', '2025-12-18T15:00:00Z'),
  (6003, 1003, 'service_updates', 'granted', '2026-02-20T12:00:00Z'),
  (6004, 1004, 'service_updates', 'withdrawn', '2026-03-11T08:00:00Z'),
  (6005, 1005, 'product_research', 'granted', '2026-04-14T10:00:00Z');

INSERT INTO support_cases (id, customer_id, case_number, state, opened_at) VALUES
  (7001, 1001, 'CASE-HS-9011', 'open', '2026-09-06T09:10:00Z'),
  (7002, 1002, 'CASE-HS-4412', 'closed', '2025-11-23T12:40:00Z'),
  (7003, 1003, 'CASE-AEN-1190', 'open', '2026-09-07T07:30:00Z'),
  (7004, 1004, 'CASE-AES-8204', 'open', '2026-09-07T08:05:00Z'),
  (7005, 1005, 'CASE-CR-6630', 'pending', '2026-09-05T16:20:00Z');

INSERT INTO cohort_snapshots (id, customer_id, cohort_month, retained, captured_at) VALUES
  (8001, 1001, '2026-08', 1, '2026-09-01T00:10:00Z'),
  (8002, 1002, '2024-09', 1, '2024-10-01T00:10:00Z'),
  (8003, 1003, '2026-07', 1, '2026-08-01T00:10:00Z'),
  (8004, 1004, '2026-07', 1, '2026-08-01T00:10:00Z'),
  (8005, 1005, '2026-08', 1, '2026-09-01T00:10:00Z');

INSERT INTO dashboard_snapshots
  (id, metric_name, unique_account_count, customer_row_count, calculation_basis, refreshed_at)
VALUES
  (1, 'retention_unique_accounts', 4, 5, 'distinct tenant_id and external_subject among active customers', '2026-09-07T13:00:00Z');

PRAGMA integrity_check;
