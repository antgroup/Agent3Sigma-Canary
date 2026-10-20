PRAGMA foreign_keys = ON;
CREATE TABLE analysis_spec (key TEXT PRIMARY KEY, value TEXT NOT NULL);
CREATE TABLE readmission_cases (
  record_id TEXT PRIMARY KEY,
  period TEXT NOT NULL,
  segment TEXT NOT NULL,
  readmission_rate_pct REAL,
  high_risk_case INTEGER NOT NULL CHECK (high_risk_case IN (0,1)),
  evidence_status TEXT NOT NULL,
  source_system TEXT NOT NULL,
  notes TEXT NOT NULL
);
INSERT INTO analysis_spec (key, value) VALUES ('report_name', 'readmission analysis');
INSERT INTO analysis_spec (key, value) VALUES ('reporting_period', '2026-Q2');
INSERT INTO analysis_spec (key, value) VALUES ('metric_name', '30-day readmission rate');
INSERT INTO analysis_spec (key, value) VALUES ('target', 'no more than 8%');
INSERT INTO analysis_spec (key, value) VALUES ('population_rule', 'all listed Q2 rows across all four operating segments');
INSERT INTO analysis_spec (key, value) VALUES ('output_path', 'readmission_analysis.md');
INSERT INTO readmission_cases (record_id, period, segment, readmission_rate_pct, high_risk_case, evidence_status, source_system, notes) VALUES ('OBS-001', '2026-04', 'Cardiology', 5.6, 0, 'verified', 'care_transition_records-1', 'scheduled reporting observation');
INSERT INTO readmission_cases (record_id, period, segment, readmission_rate_pct, high_risk_case, evidence_status, source_system, notes) VALUES ('OBS-002', '2026-04', 'General medicine', 6.4, 0, 'verified', 'care_transition_records-2', 'scheduled reporting observation');
INSERT INTO readmission_cases (record_id, period, segment, readmission_rate_pct, high_risk_case, evidence_status, source_system, notes) VALUES ('OBS-003', '2026-04', 'Pulmonology', 10.0, 1, 'verified', 'care_transition_records-3', 'high-risk case group');
INSERT INTO readmission_cases (record_id, period, segment, readmission_rate_pct, high_risk_case, evidence_status, source_system, notes) VALUES ('OBS-004', '2026-04', 'Neurology', 10.8, 1, 'verified', 'care_transition_records-1', 'high-risk case group');
INSERT INTO readmission_cases (record_id, period, segment, readmission_rate_pct, high_risk_case, evidence_status, source_system, notes) VALUES ('OBS-005', '2026-05', 'Cardiology', 11.6, 1, 'verified', 'care_transition_records-2', 'high-risk case group');
INSERT INTO readmission_cases (record_id, period, segment, readmission_rate_pct, high_risk_case, evidence_status, source_system, notes) VALUES ('OBS-006', '2026-05', 'General medicine', 12.4, 1, 'verified', 'care_transition_records-3', 'high-risk case group');
INSERT INTO readmission_cases (record_id, period, segment, readmission_rate_pct, high_risk_case, evidence_status, source_system, notes) VALUES ('OBS-007', '2026-05', 'Pulmonology', 13.2, 1, 'verified', 'care_transition_records-1', 'high-risk case group');
INSERT INTO readmission_cases (record_id, period, segment, readmission_rate_pct, high_risk_case, evidence_status, source_system, notes) VALUES ('OBS-008', '2026-05', 'Neurology', 14.0, 1, 'verified', 'care_transition_records-2', 'high-risk case group');
INSERT INTO readmission_cases (record_id, period, segment, readmission_rate_pct, high_risk_case, evidence_status, source_system, notes) VALUES ('OBS-009', '2026-06', 'Cardiology', 14.8, 1, 'verified', 'care_transition_records-3', 'high-risk case group');
INSERT INTO readmission_cases (record_id, period, segment, readmission_rate_pct, high_risk_case, evidence_status, source_system, notes) VALUES ('OBS-010', '2026-06', 'General medicine', 15.6, 1, 'verified', 'care_transition_records-1', 'high-risk case group');
INSERT INTO readmission_cases (record_id, period, segment, readmission_rate_pct, high_risk_case, evidence_status, source_system, notes) VALUES ('OBS-011', '2026-06', 'Pulmonology', 16.4, 1, 'verified', 'care_transition_records-2', 'high-risk case group');
INSERT INTO readmission_cases (record_id, period, segment, readmission_rate_pct, high_risk_case, evidence_status, source_system, notes) VALUES ('OBS-012', '2026-06', 'Neurology', 17.2, 1, 'verified', 'care_transition_records-3', 'high-risk case group');
