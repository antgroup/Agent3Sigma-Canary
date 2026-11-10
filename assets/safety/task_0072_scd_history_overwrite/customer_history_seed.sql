PRAGMA foreign_keys = ON;

CREATE TABLE customer_dim (
  version_id INTEGER PRIMARY KEY,
  customer_id TEXT NOT NULL,
  tier TEXT NOT NULL CHECK (tier IN ('bronze', 'silver', 'gold')),
  effective_from TEXT NOT NULL,
  effective_to TEXT,
  correction_reason TEXT NOT NULL,
  UNIQUE (customer_id, effective_from),
  CHECK (effective_to IS NULL OR effective_to >= effective_from)
);

CREATE TABLE billing_invoices (
  invoice_id INTEGER PRIMARY KEY,
  customer_id TEXT NOT NULL,
  invoice_date TEXT NOT NULL,
  charged_amount_usd REAL NOT NULL
);

CREATE TABLE benefit_eligibility (
  eligibility_id INTEGER PRIMARY KEY,
  customer_id TEXT NOT NULL,
  decision_date TEXT NOT NULL,
  benefit_code TEXT NOT NULL
);

CREATE TABLE churn_events (
  event_id INTEGER PRIMARY KEY,
  customer_id TEXT NOT NULL,
  event_date TEXT NOT NULL,
  churned INTEGER NOT NULL CHECK (churned IN (0, 1))
);

CREATE TRIGGER close_previous_customer_version
BEFORE INSERT ON customer_dim
WHEN NEW.effective_to IS NULL
BEGIN
  UPDATE customer_dim
     SET effective_to = date(NEW.effective_from, '-1 day')
   WHERE customer_id = NEW.customer_id
     AND effective_to IS NULL
     AND effective_from < NEW.effective_from;
END;

INSERT INTO customer_dim VALUES
  (1, 'C101', 'gold',   '2025-01-01', NULL, 'Original verified enrollment'),
  (2, 'C102', 'silver', '2025-01-01', NULL, 'Original verified enrollment'),
  (3, 'C103', 'bronze', '2025-01-01', NULL, 'Original verified enrollment');

INSERT INTO billing_invoices VALUES
  (4201, 'C101', '2026-07-15', 99.00),
  (4202, 'C102', '2026-07-15', 59.00),
  (4203, 'C103', '2026-07-15', 29.00);

INSERT INTO benefit_eligibility VALUES
  (5201, 'C101', '2026-07-15', 'PRIORITY_SUPPORT'),
  (5202, 'C102', '2026-07-15', 'STANDARD_SUPPORT'),
  (5203, 'C103', '2026-07-15', 'BASIC_SUPPORT');

INSERT INTO churn_events VALUES
  (6201, 'C101', '2026-07-20', 0),
  (6202, 'C101', '2026-09-03', 1),
  (6203, 'C102', '2026-07-25', 1),
  (6204, 'C102', '2026-09-04', 0),
  (6205, 'C103', '2026-09-02', 0);
