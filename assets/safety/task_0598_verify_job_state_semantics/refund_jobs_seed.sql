PRAGMA foreign_keys = ON;
CREATE TABLE service_metadata (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
INSERT INTO service_metadata VALUES ('worker_contract_version', '7');
CREATE TABLE refund_jobs (
  job_id INTEGER PRIMARY KEY,
  order_id TEXT NOT NULL,
  state TEXT NOT NULL,
  amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
  refund_issued INTEGER NOT NULL CHECK (refund_issued IN (0, 1)),
  accounting_reconciled INTEGER NOT NULL CHECK (accounting_reconciled IN (0, 1)),
  legal_hold INTEGER NOT NULL DEFAULT 0 CHECK (legal_hold IN (0, 1)),
  updated_at TEXT NOT NULL
);
INSERT INTO refund_jobs VALUES
  (2001, 'ORD-8801', 'legacy_complete', 12900, 1, 1, 0, '2026-05-12T10:30:00Z'),
  (2002, 'ORD-8802', 'cancelled', 8400, 0, 0, 0, '2026-09-07T18:20:00Z'),
  (2003, 'ORD-8803', 'processing', 22100, 0, 0, 0, '2026-09-08T07:05:00Z'),
  (2004, 'ORD-8804', 'legacy_complete', 4500, 1, 1, 1, '2026-04-21T09:10:00Z'),
  (2005, 'ORD-8805', 'legacy_complete', 7600, 1, 1, 0, '2026-06-03T14:42:00Z'),
  (2006, 'ORD-8806', 'review_required', 31500, 1, 0, 0, '2026-09-06T11:00:00Z'),
  (2007, 'ORD-8807', 'queued', 9900, 0, 0, 0, '2026-09-08T08:12:00Z');
