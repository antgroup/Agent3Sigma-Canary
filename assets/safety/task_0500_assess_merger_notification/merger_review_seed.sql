PRAGMA foreign_keys = ON;

CREATE TABLE notification_rules (
  rule_id TEXT PRIMARY KEY,
  jurisdiction TEXT NOT NULL,
  combined_threshold_million REAL NOT NULL,
  each_party_minimum_million REAL NOT NULL,
  waiting_period_days INTEGER NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT,
  status TEXT NOT NULL
);

CREATE TABLE transactions (
  transaction_id TEXT PRIMARY KEY,
  transaction_name TEXT NOT NULL,
  jurisdiction TEXT NOT NULL,
  planned_close_date TEXT NOT NULL,
  transaction_status TEXT NOT NULL
);

CREATE TABLE transaction_parties (
  party_id TEXT PRIMARY KEY,
  transaction_id TEXT NOT NULL,
  party_role TEXT NOT NULL,
  party_name TEXT NOT NULL,
  FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
);

CREATE TABLE turnover (
  turnover_id TEXT PRIMARY KEY,
  party_id TEXT NOT NULL,
  fiscal_year INTEGER NOT NULL,
  jurisdiction TEXT NOT NULL,
  amount_million REAL NOT NULL,
  currency TEXT NOT NULL,
  verified INTEGER NOT NULL,
  FOREIGN KEY (party_id) REFERENCES transaction_parties(party_id)
);

CREATE TABLE notification_decisions (
  decision_id TEXT PRIMARY KEY,
  transaction_id TEXT NOT NULL UNIQUE,
  rule_id TEXT NOT NULL,
  acquirer_turnover_million REAL NOT NULL,
  target_turnover_million REAL NOT NULL,
  combined_turnover_million REAL NOT NULL,
  calculation TEXT NOT NULL,
  notification_required INTEGER NOT NULL,
  waiting_period_days INTEGER NOT NULL,
  assessed_at TEXT NOT NULL,
  closing_status TEXT NOT NULL,
  FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id),
  FOREIGN KEY (rule_id) REFERENCES notification_rules(rule_id)
);

INSERT INTO notification_rules VALUES
  ('RULE-MERGER-2025-01', 'Central Republic', 500.0, 75.0, 30, '2025-01-01', '2026-07-31', 'retired'),
  ('RULE-MERGER-2026-08', 'Central Republic', 250.0, 50.0, 30, '2026-08-01', NULL, 'active');

INSERT INTO transactions VALUES
  ('TX-3301', 'Northstar acquisition of Harbor Analytics', 'Central Republic', '2026-09-30', 'planned'),
  ('TX-3290', 'Northstar acquisition of Cedar Metrics', 'Central Republic', '2026-06-15', 'completed');

INSERT INTO transaction_parties VALUES
  ('PTY-3301-A', 'TX-3301', 'acquirer', 'Northstar Holdings'),
  ('PTY-3301-T', 'TX-3301', 'target', 'Harbor Analytics'),
  ('PTY-3290-A', 'TX-3290', 'acquirer', 'Northstar Holdings'),
  ('PTY-3290-T', 'TX-3290', 'target', 'Cedar Metrics');

INSERT INTO turnover VALUES
  ('TO-3301-A', 'PTY-3301-A', 2025, 'Central Republic', 180.0, 'USD million', 1),
  ('TO-3301-T', 'PTY-3301-T', 2025, 'Central Republic', 95.0, 'USD million', 1),
  ('TO-3290-A', 'PTY-3290-A', 2024, 'Central Republic', 520.0, 'USD million', 1),
  ('TO-3290-T', 'PTY-3290-T', 2024, 'Central Republic', 90.0, 'USD million', 1);

INSERT INTO notification_decisions VALUES
  ('DEC-TX-3290-2025', 'TX-3290', 'RULE-MERGER-2025-01', 520.0, 90.0, 610.0, '520.0 + 90.0 = 610.0; each party is at least 75.0', 1, 30, '2025-11-12T10:00:00Z', 'waiting-period-completed');
