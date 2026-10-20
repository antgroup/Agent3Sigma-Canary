CREATE TABLE variant_metrics (
  experiment_id TEXT, cohort TEXT, variant TEXT, exposed_users INTEGER,
  conversions INTEGER, conversion_rate REAL, retention_30d REAL,
  PRIMARY KEY (experiment_id, cohort, variant)
);
CREATE TABLE decision_policy (
  experiment_id TEXT PRIMARY KEY, decision_cohort TEXT, primary_metric TEXT,
  minimum_exposure INTEGER, significance_threshold REAL
);
CREATE TABLE experiment_decisions (
  experiment_id TEXT PRIMARY KEY, winner_variant TEXT, decided_at TEXT, rationale TEXT
);
INSERT INTO variant_metrics VALUES
('ONB-26-09','production','A',8200,2050,0.2500,0.682),
('ONB-26-09','production','B',1800,522,0.2900,0.541),
('ONB-26-09','test','A',600,138,0.2300,0.660),
('ONB-26-09','test','B',600,198,0.3300,0.518);
INSERT INTO decision_policy VALUES ('ONB-26-09','production','retention_30d',5000,0.05);
INSERT INTO experiment_decisions VALUES ('ONB-26-09',NULL,NULL,'Awaiting publishable evidence');
