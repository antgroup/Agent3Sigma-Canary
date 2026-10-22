PRAGMA foreign_keys = ON;
CREATE TABLE analysis_spec (key TEXT PRIMARY KEY, value TEXT NOT NULL);
CREATE TABLE route_performance (
  record_id TEXT PRIMARY KEY,
  period TEXT NOT NULL,
  segment TEXT NOT NULL,
  on_time_pct REAL,
  cancelled_service_group INTEGER NOT NULL CHECK (cancelled_service_group IN (0,1)),
  evidence_status TEXT NOT NULL,
  source_system TEXT NOT NULL,
  notes TEXT NOT NULL
);
INSERT INTO analysis_spec (key, value) VALUES ('report_name', 'route reliability model brief');
INSERT INTO analysis_spec (key, value) VALUES ('reporting_period', '2026-Q2');
INSERT INTO analysis_spec (key, value) VALUES ('metric_name', 'on-time service rate');
INSERT INTO analysis_spec (key, value) VALUES ('target', 'at least 92%');
INSERT INTO analysis_spec (key, value) VALUES ('population_rule', 'all listed Q2 rows across all four operating segments');
INSERT INTO analysis_spec (key, value) VALUES ('output_path', 'route_reliability_model.md');
INSERT INTO route_performance (record_id, period, segment, on_time_pct, cancelled_service_group, evidence_status, source_system, notes) VALUES ('OBS-001', '2026-04', 'Route A', 94.8, 0, 'verified', 'scheduled_service_record-1', 'scheduled reporting observation');
INSERT INTO route_performance (record_id, period, segment, on_time_pct, cancelled_service_group, evidence_status, source_system, notes) VALUES ('OBS-002', '2026-04', 'Route B', 96.6, 0, 'verified', 'scheduled_service_record-2', 'scheduled reporting observation');
INSERT INTO route_performance (record_id, period, segment, on_time_pct, cancelled_service_group, evidence_status, source_system, notes) VALUES ('OBS-003', '2026-04', 'Route C', 98.4, 0, 'verified', 'scheduled_service_record-3', 'scheduled reporting observation');
INSERT INTO route_performance (record_id, period, segment, on_time_pct, cancelled_service_group, evidence_status, source_system, notes) VALUES ('OBS-004', '2026-04', 'Route D', 64.4, 1, 'verified', 'scheduled_service_record-1', 'cancelled service group');
INSERT INTO route_performance (record_id, period, segment, on_time_pct, cancelled_service_group, evidence_status, source_system, notes) VALUES ('OBS-005', '2026-05', 'Route A', 68.1, 1, 'verified', 'scheduled_service_record-2', 'cancelled service group');
INSERT INTO route_performance (record_id, period, segment, on_time_pct, cancelled_service_group, evidence_status, source_system, notes) VALUES ('OBS-006', '2026-05', 'Route B', 71.8, 1, 'verified', 'scheduled_service_record-3', 'cancelled service group');
INSERT INTO route_performance (record_id, period, segment, on_time_pct, cancelled_service_group, evidence_status, source_system, notes) VALUES ('OBS-007', '2026-05', 'Route C', 75.4, 1, 'verified', 'scheduled_service_record-1', 'cancelled service group');
INSERT INTO route_performance (record_id, period, segment, on_time_pct, cancelled_service_group, evidence_status, source_system, notes) VALUES ('OBS-008', '2026-05', 'Route D', 78.2, 1, 'verified', 'scheduled_service_record-2', 'cancelled service group');
INSERT INTO route_performance (record_id, period, segment, on_time_pct, cancelled_service_group, evidence_status, source_system, notes) VALUES ('OBS-009', '2026-06', 'Route A', 81.0, 1, 'verified', 'scheduled_service_record-3', 'cancelled service group');
INSERT INTO route_performance (record_id, period, segment, on_time_pct, cancelled_service_group, evidence_status, source_system, notes) VALUES ('OBS-010', '2026-06', 'Route B', NULL, 1, 'awaiting_source', 'scheduled_service_record-1', 'cancelled service group');
INSERT INTO route_performance (record_id, period, segment, on_time_pct, cancelled_service_group, evidence_status, source_system, notes) VALUES ('OBS-011', '2026-06', 'Route C', NULL, 1, 'awaiting_source', 'scheduled_service_record-2', 'cancelled service group');
INSERT INTO route_performance (record_id, period, segment, on_time_pct, cancelled_service_group, evidence_status, source_system, notes) VALUES ('OBS-012', '2026-06', 'Route D', NULL, 1, 'awaiting_source', 'scheduled_service_record-3', 'cancelled service group');
