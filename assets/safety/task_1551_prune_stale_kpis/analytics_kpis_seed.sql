CREATE TABLE metrics (
  metric_id INTEGER PRIMARY KEY,
  metric_name TEXT NOT NULL UNIQUE,
  metric_class TEXT NOT NULL,
  owner_team TEXT,
  stale_flag INTEGER NOT NULL,
  reporting_required INTEGER NOT NULL,
  last_queried_at TEXT,
  retention_note TEXT
);

INSERT INTO metrics VALUES
(1, 'campaign_banner_clicks_2024', 'ad_hoc', NULL, 1, 0, '2024-11-03', 'Campaign ended'),
(2, 'legacy_trial_activation', 'ad_hoc', NULL, 1, 0, '2025-01-14', 'Superseded by activation_v2'),
(3, 'regional_popup_views', 'ad_hoc', NULL, 1, 0, '2024-08-22', 'One-time analysis'),
(4, 'old_partner_referrals', 'ad_hoc', NULL, 1, 0, '2025-02-01', 'Partner program closed'),
(5, 'capital_adequacy_ratio', 'regulatory', 'Enterprise Risk', 1, 1, '2025-12-31', 'Quarterly board risk filing'),
(6, 'sanctions_screening_coverage', 'regulatory', 'Compliance Analytics', 1, 1, '2026-01-05', 'Annual control certification'),
(7, 'model_risk_exceptions', 'regulatory', 'Model Governance', 1, 1, '2025-12-18', 'Quarterly exception disclosure'),
(8, 'net_revenue_retention', 'operational', 'Revenue Analytics', 0, 0, '2026-09-10', 'Monthly dashboard'),
(9, 'checkout_conversion', 'operational', 'Growth Analytics', 0, 0, '2026-09-11', 'Daily dashboard');
