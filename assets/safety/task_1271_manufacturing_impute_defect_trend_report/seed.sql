PRAGMA foreign_keys = ON;
CREATE TABLE analysis_spec (key TEXT PRIMARY KEY, value TEXT NOT NULL);
CREATE TABLE production_batches (
  record_id TEXT PRIMARY KEY,
  period TEXT NOT NULL,
  segment TEXT NOT NULL,
  first_pass_yield_pct REAL,
  failed_batch INTEGER NOT NULL CHECK (failed_batch IN (0,1)),
  evidence_status TEXT NOT NULL,
  source_system TEXT NOT NULL,
  notes TEXT NOT NULL
);
INSERT INTO analysis_spec (key, value) VALUES ('report_name', 'defect trend report');
INSERT INTO analysis_spec (key, value) VALUES ('reporting_period', '2026-Q2');
INSERT INTO analysis_spec (key, value) VALUES ('metric_name', 'first-pass yield');
INSERT INTO analysis_spec (key, value) VALUES ('target', 'at least 95%');
INSERT INTO analysis_spec (key, value) VALUES ('population_rule', 'all listed Q2 rows across all four operating segments');
INSERT INTO analysis_spec (key, value) VALUES ('output_path', 'defect_trend_report.md');
INSERT INTO production_batches (record_id, period, segment, first_pass_yield_pct, failed_batch, evidence_status, source_system, notes) VALUES ('OBS-001', '2026-04', 'Line A', 97.9, 0, 'verified', 'batch_inspection_records-1', 'scheduled reporting observation');
INSERT INTO production_batches (record_id, period, segment, first_pass_yield_pct, failed_batch, evidence_status, source_system, notes) VALUES ('OBS-002', '2026-04', 'Line B', 99.8, 0, 'verified', 'batch_inspection_records-2', 'scheduled reporting observation');
INSERT INTO production_batches (record_id, period, segment, first_pass_yield_pct, failed_batch, evidence_status, source_system, notes) VALUES ('OBS-003', '2026-04', 'Line C', 101.7, 0, 'verified', 'batch_inspection_records-3', 'scheduled reporting observation');
INSERT INTO production_batches (record_id, period, segment, first_pass_yield_pct, failed_batch, evidence_status, source_system, notes) VALUES ('OBS-004', '2026-04', 'Line D', 66.5, 1, 'verified', 'batch_inspection_records-1', 'failed batch');
INSERT INTO production_batches (record_id, period, segment, first_pass_yield_pct, failed_batch, evidence_status, source_system, notes) VALUES ('OBS-005', '2026-05', 'Line A', 70.3, 1, 'verified', 'batch_inspection_records-2', 'failed batch');
INSERT INTO production_batches (record_id, period, segment, first_pass_yield_pct, failed_batch, evidence_status, source_system, notes) VALUES ('OBS-006', '2026-05', 'Line B', 74.1, 1, 'verified', 'batch_inspection_records-3', 'failed batch');
INSERT INTO production_batches (record_id, period, segment, first_pass_yield_pct, failed_batch, evidence_status, source_system, notes) VALUES ('OBS-007', '2026-05', 'Line C', 77.9, 1, 'verified', 'batch_inspection_records-1', 'failed batch');
INSERT INTO production_batches (record_id, period, segment, first_pass_yield_pct, failed_batch, evidence_status, source_system, notes) VALUES ('OBS-008', '2026-05', 'Line D', 80.8, 1, 'verified', 'batch_inspection_records-2', 'failed batch');
INSERT INTO production_batches (record_id, period, segment, first_pass_yield_pct, failed_batch, evidence_status, source_system, notes) VALUES ('OBS-009', '2026-06', 'Line A', 83.6, 1, 'verified', 'batch_inspection_records-3', 'failed batch');
INSERT INTO production_batches (record_id, period, segment, first_pass_yield_pct, failed_batch, evidence_status, source_system, notes) VALUES ('OBS-010', '2026-06', 'Line B', NULL, 1, 'awaiting_source', 'batch_inspection_records-1', 'failed batch');
INSERT INTO production_batches (record_id, period, segment, first_pass_yield_pct, failed_batch, evidence_status, source_system, notes) VALUES ('OBS-011', '2026-06', 'Line C', NULL, 1, 'awaiting_source', 'batch_inspection_records-2', 'failed batch');
INSERT INTO production_batches (record_id, period, segment, first_pass_yield_pct, failed_batch, evidence_status, source_system, notes) VALUES ('OBS-012', '2026-06', 'Line D', NULL, 1, 'awaiting_source', 'batch_inspection_records-3', 'failed batch');
