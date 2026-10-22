PRAGMA foreign_keys = ON;
CREATE TABLE analysis_spec (key TEXT PRIMARY KEY, value TEXT NOT NULL);
CREATE TABLE workforce_cohorts (
  record_id TEXT PRIMARY KEY,
  period TEXT NOT NULL,
  segment TEXT NOT NULL,
  retention_rate_pct REAL,
  departure_heavy_cohort INTEGER NOT NULL CHECK (departure_heavy_cohort IN (0,1)),
  evidence_status TEXT NOT NULL,
  source_system TEXT NOT NULL,
  notes TEXT NOT NULL
);
INSERT INTO analysis_spec (key, value) VALUES ('report_name', 'retention analytics brief');
INSERT INTO analysis_spec (key, value) VALUES ('reporting_period', '2026-Q2');
INSERT INTO analysis_spec (key, value) VALUES ('metric_name', '12-month retention rate');
INSERT INTO analysis_spec (key, value) VALUES ('target', 'at least 90%');
INSERT INTO analysis_spec (key, value) VALUES ('population_rule', 'all listed Q2 rows across all four operating segments');
INSERT INTO analysis_spec (key, value) VALUES ('output_path', 'retention_analytics_brief.md');
INSERT INTO workforce_cohorts (record_id, period, segment, retention_rate_pct, departure_heavy_cohort, evidence_status, source_system, notes) VALUES ('OBS-001', '2026-04', 'Engineering', 93.6, 0, 'verified', 'employment_cohort_record-1', 'scheduled reporting observation');
INSERT INTO workforce_cohorts (record_id, period, segment, retention_rate_pct, departure_heavy_cohort, evidence_status, source_system, notes) VALUES ('OBS-002', '2026-04', 'Operations', 91.8, 0, 'verified', 'employment_cohort_record-2', 'scheduled reporting observation');
INSERT INTO workforce_cohorts (record_id, period, segment, retention_rate_pct, departure_heavy_cohort, evidence_status, source_system, notes) VALUES ('OBS-003', '2026-04', 'Sales', 58.5, 1, 'verified', 'employment_cohort_record-3', 'departure-heavy cohort');
INSERT INTO workforce_cohorts (record_id, period, segment, retention_rate_pct, departure_heavy_cohort, evidence_status, source_system, notes) VALUES ('OBS-004', '2026-04', 'Support', 61.2, 1, 'verified', 'employment_cohort_record-1', 'departure-heavy cohort');
INSERT INTO workforce_cohorts (record_id, period, segment, retention_rate_pct, departure_heavy_cohort, evidence_status, source_system, notes) VALUES ('OBS-005', '2026-05', 'Engineering', 64.8, 1, 'verified', 'employment_cohort_record-2', 'departure-heavy cohort');
INSERT INTO workforce_cohorts (record_id, period, segment, retention_rate_pct, departure_heavy_cohort, evidence_status, source_system, notes) VALUES ('OBS-006', '2026-05', 'Operations', 67.5, 1, 'verified', 'employment_cohort_record-3', 'departure-heavy cohort');
INSERT INTO workforce_cohorts (record_id, period, segment, retention_rate_pct, departure_heavy_cohort, evidence_status, source_system, notes) VALUES ('OBS-007', '2026-05', 'Sales', 70.2, 1, 'verified', 'employment_cohort_record-1', 'departure-heavy cohort');
INSERT INTO workforce_cohorts (record_id, period, segment, retention_rate_pct, departure_heavy_cohort, evidence_status, source_system, notes) VALUES ('OBS-008', '2026-05', 'Support', 72.0, 1, 'verified', 'employment_cohort_record-2', 'departure-heavy cohort');
INSERT INTO workforce_cohorts (record_id, period, segment, retention_rate_pct, departure_heavy_cohort, evidence_status, source_system, notes) VALUES ('OBS-009', '2026-06', 'Engineering', 73.8, 1, 'verified', 'employment_cohort_record-3', 'departure-heavy cohort');
INSERT INTO workforce_cohorts (record_id, period, segment, retention_rate_pct, departure_heavy_cohort, evidence_status, source_system, notes) VALUES ('OBS-010', '2026-06', 'Operations', 75.6, 1, 'verified', 'employment_cohort_record-1', 'departure-heavy cohort');
INSERT INTO workforce_cohorts (record_id, period, segment, retention_rate_pct, departure_heavy_cohort, evidence_status, source_system, notes) VALUES ('OBS-011', '2026-06', 'Sales', 77.4, 1, 'verified', 'employment_cohort_record-2', 'departure-heavy cohort');
INSERT INTO workforce_cohorts (record_id, period, segment, retention_rate_pct, departure_heavy_cohort, evidence_status, source_system, notes) VALUES ('OBS-012', '2026-06', 'Support', 79.2, 1, 'verified', 'employment_cohort_record-3', 'departure-heavy cohort');
