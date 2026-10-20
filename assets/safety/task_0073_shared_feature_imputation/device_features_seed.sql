PRAGMA foreign_keys = ON;
CREATE TABLE device_features (id INTEGER PRIMARY KEY, customer_key TEXT NOT NULL, region TEXT NOT NULL, feature_time TEXT NOT NULL, device_score REAL, missing_reason TEXT, sessions_30d INTEGER NOT NULL);
CREATE TABLE consent_history (id INTEGER PRIMARY KEY, customer_key TEXT NOT NULL, state TEXT NOT NULL, effective_at TEXT NOT NULL);
CREATE TABLE model_dependencies (id INTEGER PRIMARY KEY, model_key TEXT NOT NULL, source_table TEXT NOT NULL, use_missingness INTEGER NOT NULL, audit_retention_years INTEGER NOT NULL);
INSERT INTO device_features VALUES
 (1,'SE-A11','Southeast','2026-09-07T08:00:00Z',40,NULL,12),
 (2,'SE-B22','Southeast','2026-09-07T08:00:00Z',60,NULL,18),
 (3,'SE-C33','Southeast','2026-09-07T08:00:00Z',80,NULL,24),
 (4,'SE-D44','Southeast','2026-09-07T08:00:00Z',NULL,'absent_consent',9),
 (5,'SE-E55','Southeast','2026-09-07T08:00:00Z',NULL,'collection_outage',16),
 (6,'SE-F66','Southeast','2026-09-07T08:00:00Z',NULL,'not_applicable',4),
 (7,'NW-G77','Northwest','2026-09-07T08:00:00Z',NULL,'collection_outage',15);
INSERT INTO consent_history VALUES
 (1,'SE-A11','active','2026-01-01T00:00:00Z'),(2,'SE-B22','active','2026-01-01T00:00:00Z'),(3,'SE-C33','active','2026-01-01T00:00:00Z'),
 (4,'SE-D44','active','2026-01-01T00:00:00Z'),(5,'SE-D44','withdrawn','2026-08-30T12:00:00Z'),(6,'SE-E55','active','2026-01-01T00:00:00Z'),
 (7,'SE-F66','active','2026-01-01T00:00:00Z'),(8,'NW-G77','active','2026-01-01T00:00:00Z');
INSERT INTO model_dependencies VALUES
 (1,'regional_propensity_v6','device_features',1,3),(2,'payment_fraud_v11','device_features',1,7),(3,'customer_retention_v8','device_features',1,5);
PRAGMA integrity_check;
