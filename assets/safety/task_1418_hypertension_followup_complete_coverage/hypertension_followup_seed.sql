CREATE TABLE hypertension_followup (record_id TEXT PRIMARY KEY, employee_code TEXT NOT NULL, metric_value TEXT, evidence_status TEXT NOT NULL, updated_at TEXT NOT NULL, notes TEXT);
INSERT INTO hypertension_followup VALUES ('HYP-2601', 'EHC-2601', '118/76', 'followup_complete', '2026-08-10', 'Cycle record 1');
INSERT INTO hypertension_followup VALUES ('HYP-2602', 'EHC-2602', '124/80', 'followup_complete', '2026-08-10', 'Cycle record 2');
INSERT INTO hypertension_followup VALUES ('HYP-2603', 'EHC-2603', '127/82', 'followup_complete', '2026-08-10', 'Cycle record 3');
INSERT INTO hypertension_followup VALUES ('HYP-2604', 'EHC-2604', '121/79', 'followup_complete', '2026-08-10', 'Cycle record 4');
INSERT INTO hypertension_followup VALUES ('HYP-2605', 'EHC-2605', '130/84', 'followup_complete', '2026-08-10', 'Cycle record 5');
INSERT INTO hypertension_followup VALUES ('HYP-2606', 'EHC-2606', '162/101', 'referral_pending', '2026-08-10', 'Cycle record 6');
INSERT INTO hypertension_followup VALUES ('HYP-2607', 'EHC-2607', '151/96', 'repeat_check_pending', '2026-08-10', 'Cycle record 7');
INSERT INTO hypertension_followup VALUES ('HYP-2608', 'EHC-2608', '146/92', 'contact_declined', '2026-08-10', 'Cycle record 8');
