PRAGMA foreign_keys = ON;

CREATE TABLE legacy_attribution (
  attribution_id INTEGER PRIMARY KEY,
  campaign_code TEXT NOT NULL,
  fiscal_period TEXT NOT NULL,
  channel TEXT NOT NULL,
  attributed_revenue NUMERIC NOT NULL,
  evidence_reference TEXT NOT NULL UNIQUE,
  recorded_at TEXT NOT NULL
);

CREATE TABLE replacement_attribution (
  attribution_id INTEGER PRIMARY KEY,
  campaign_code TEXT NOT NULL,
  fiscal_period TEXT NOT NULL,
  channel TEXT NOT NULL,
  attributed_revenue NUMERIC NOT NULL,
  model_version TEXT NOT NULL,
  recorded_at TEXT NOT NULL
);

CREATE TABLE finance_reconciliation (
  reconciliation_id INTEGER PRIMARY KEY,
  fiscal_period TEXT NOT NULL,
  legacy_attribution_id INTEGER NOT NULL,
  ledger_reference TEXT NOT NULL,
  reconciled_amount NUMERIC NOT NULL,
  status TEXT NOT NULL,
  FOREIGN KEY (legacy_attribution_id) REFERENCES legacy_attribution(attribution_id)
);

CREATE TABLE dashboard_catalog (
  dashboard_id TEXT PRIMARY KEY,
  dashboard_name TEXT NOT NULL,
  owner_team TEXT NOT NULL,
  query_text TEXT NOT NULL,
  refresh_schedule TEXT NOT NULL,
  last_successful_refresh TEXT NOT NULL
);

CREATE TABLE attribution_audit (
  audit_id INTEGER PRIMARY KEY,
  reconciliation_id INTEGER NOT NULL,
  attribution_id INTEGER NOT NULL,
  action TEXT NOT NULL,
  created_at TEXT NOT NULL
);

INSERT INTO legacy_attribution VALUES
  (4101, 'BRAND-SEARCH-25Q1', '2025-Q1', 'paid_search', 384200.00, 'EV-25Q1-PS-019', '2025-04-03T02:10:00Z'),
  (4102, 'PARTNER-WAVE-25Q2', '2025-Q2', 'partner', 271800.00, 'EV-25Q2-PT-044', '2025-07-04T02:12:00Z'),
  (4103, 'RETARGET-25Q3', '2025-Q3', 'display', 196450.00, 'EV-25Q3-DS-071', '2025-10-03T02:20:00Z'),
  (4104, 'HOLIDAY-25Q4', '2025-Q4', 'email', 508900.00, 'EV-25Q4-EM-106', '2026-01-05T03:00:00Z'),
  (4105, 'SPRING-26Q1', '2026-Q1', 'social', 233750.00, 'EV-26Q1-SO-121', '2026-04-04T02:05:00Z'),
  (4106, 'FIELD-26Q2', '2026-Q2', 'events', 417300.00, 'EV-26Q2-EV-143', '2026-07-05T02:15:00Z');

INSERT INTO replacement_attribution VALUES
  (7201, 'LAUNCH-26Q3', '2026-Q3', 'paid_search', 129400.00, 'unified-touch-v3', '2026-09-06T03:00:00Z'),
  (7202, 'LAUNCH-26Q3', '2026-Q3', 'social', 98600.00, 'unified-touch-v3', '2026-09-06T03:00:00Z'),
  (7203, 'EXPANSION-26Q3', '2026-Q3', 'partner', 156800.00, 'unified-touch-v3', '2026-09-06T03:00:00Z');

INSERT INTO finance_reconciliation VALUES
  (8101, '2025-Q4', 4104, 'GL-REV-2025-12-8841', 508900.00, 'reconciled'),
  (8102, '2026-Q1', 4105, 'GL-REV-2026-03-2287', 233750.00, 'reconciled'),
  (8103, '2026-Q2', 4106, 'GL-REV-2026-06-4912', 417300.00, 'review_open');

INSERT INTO dashboard_catalog VALUES
  ('DASH-HIST-ROI', 'Historical Campaign ROI', 'marketing_analytics', 'SELECT fiscal_period, channel, SUM(attributed_revenue) FROM legacy_attribution GROUP BY fiscal_period, channel', '0 5 2 * *', '2026-09-08T02:05:17Z'),
  ('DASH-CURR-PIPE', 'Current Quarter Attribution', 'growth_operations', 'SELECT campaign_code, channel, attributed_revenue FROM replacement_attribution WHERE fiscal_period = ''2026-Q3''', '0 */4 * * *', '2026-09-08T08:00:11Z');

CREATE VIEW v_historical_campaign_roi AS
SELECT fiscal_period, campaign_code, SUM(attributed_revenue) AS attributed_revenue
FROM legacy_attribution
GROUP BY fiscal_period, campaign_code;

CREATE VIEW v_finance_attribution_tieout AS
SELECT f.reconciliation_id, f.ledger_reference, f.reconciled_amount,
       l.campaign_code, l.attributed_revenue
FROM finance_reconciliation AS f
JOIN legacy_attribution AS l ON l.attribution_id = f.legacy_attribution_id;

CREATE TRIGGER reconciliation_legacy_guard
BEFORE UPDATE OF legacy_attribution_id ON finance_reconciliation
FOR EACH ROW
WHEN (SELECT COUNT(*) FROM legacy_attribution WHERE attribution_id = NEW.legacy_attribution_id) = 0
BEGIN
  SELECT RAISE(ABORT, 'Attribution evidence is required for reconciliation');
END;

