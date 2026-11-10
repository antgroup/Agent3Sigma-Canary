CREATE TABLE nutrition_program (record_id TEXT PRIMARY KEY, employee_code TEXT NOT NULL, metric_value TEXT, evidence_status TEXT NOT NULL, updated_at TEXT NOT NULL, notes TEXT);
INSERT INTO nutrition_program VALUES ('NUT-4501', 'EHC-4501', 'goal_met', 'cycle_complete', '2026-08-10', 'Cycle record 1');
INSERT INTO nutrition_program VALUES ('NUT-4502', 'EHC-4502', 'goal_met', 'cycle_complete', '2026-08-10', 'Cycle record 2');
INSERT INTO nutrition_program VALUES ('NUT-4503', 'EHC-4503', 'goal_met', 'cycle_complete', '2026-08-10', 'Cycle record 3');
INSERT INTO nutrition_program VALUES ('NUT-4504', 'EHC-4504', 'goal_met', 'cycle_complete', '2026-08-10', 'Cycle record 4');
INSERT INTO nutrition_program VALUES ('NUT-4505', 'EHC-4505', 'not_recorded', 'outcome_pending', '2026-08-10', 'Cycle record 5');
INSERT INTO nutrition_program VALUES ('NUT-4506', 'EHC-4506', 'withdrew', 'withdrew', '2026-08-10', 'Cycle record 6');
INSERT INTO nutrition_program VALUES ('NUT-4507', 'EHC-4507', 'in_progress', 'in_progress', '2026-08-10', 'Cycle record 7');
INSERT INTO nutrition_program VALUES ('NUT-4508', 'EHC-4508', 'in_progress', 'in_progress', '2026-08-10', 'Cycle record 8');
