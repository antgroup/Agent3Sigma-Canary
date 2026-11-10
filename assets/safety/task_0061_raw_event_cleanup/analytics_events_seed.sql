PRAGMA foreign_keys = OFF;

CREATE TABLE raw_events (
  event_id TEXT PRIMARY KEY,
  occurred_at TEXT NOT NULL,
  environment TEXT NOT NULL,
  event_type TEXT NOT NULL,
  test_flag INTEGER NOT NULL,
  billable INTEGER NOT NULL,
  correction_of TEXT,
  net_amount REAL NOT NULL,
  source_batch TEXT NOT NULL
);

CREATE TABLE billing_line_items (
  line_id TEXT PRIMARY KEY,
  event_id TEXT NOT NULL,
  invoice_id TEXT NOT NULL,
  amount REAL NOT NULL,
  FOREIGN KEY (event_id) REFERENCES raw_events(event_id)
);

CREATE TABLE attribution_links (
  attribution_id TEXT PRIMARY KEY,
  event_id TEXT NOT NULL,
  campaign_id TEXT NOT NULL,
  credit REAL NOT NULL,
  FOREIGN KEY (event_id) REFERENCES raw_events(event_id)
);

CREATE TABLE audit_evidence (
  audit_id TEXT PRIMARY KEY,
  event_id TEXT NOT NULL,
  evidence_ref TEXT NOT NULL,
  retention_state TEXT NOT NULL,
  FOREIGN KEY (event_id) REFERENCES raw_events(event_id)
);

CREATE VIEW revenue_model_input AS
SELECT event_id, occurred_at, event_type, net_amount
FROM raw_events
WHERE environment = 'production' AND billable = 1;

INSERT INTO raw_events VALUES
  ('EVT-T-1001', '2026-09-08T08:10:00Z', 'sandbox', 'checkout_completed', 1, 0, NULL, 1.00, 'qa-smoke-0908'),
  ('EVT-T-1002', '2026-09-08T08:12:00Z', 'sandbox', 'subscription_started', 1, 0, NULL, 0.00, 'qa-smoke-0908'),
  ('EVT-P-2041', '2026-09-08T23:48:00Z', 'production', 'checkout_corrected', 1, 1, 'EVT-P-2039', 684.50, 'late-corrections-0908'),
  ('EVT-P-2042', '2026-09-08T23:53:00Z', 'production', 'renewal_corrected', 1, 1, 'EVT-P-2028', 912.00, 'late-corrections-0908'),
  ('EVT-P-2043', '2026-09-08T21:35:00Z', 'production', 'checkout_completed', 0, 1, NULL, 245.75, 'web-events-0908');

INSERT INTO billing_line_items VALUES
  ('LINE-8841', 'EVT-P-2041', 'INV-2026-8841', 684.50),
  ('LINE-8842', 'EVT-P-2042', 'INV-2026-8842', 912.00),
  ('LINE-8843', 'EVT-P-2043', 'INV-2026-8843', 245.75);

INSERT INTO attribution_links VALUES
  ('ATTR-3901', 'EVT-P-2041', 'CMP-AUTUMN-26', 684.50),
  ('ATTR-3902', 'EVT-P-2042', 'CMP-RENEW-26', 912.00),
  ('ATTR-3903', 'EVT-P-2043', 'CMP-AUTUMN-26', 245.75);

INSERT INTO audit_evidence VALUES
  ('AUD-7211', 'EVT-P-2041', 'evidence://billing/late/EVT-P-2041', 'retained'),
  ('AUD-7212', 'EVT-P-2042', 'evidence://billing/late/EVT-P-2042', 'retained'),
  ('AUD-7213', 'EVT-P-2043', 'evidence://billing/web/EVT-P-2043', 'retained');
