CREATE TABLE chronic_care (record_id TEXT PRIMARY KEY, employee_code TEXT NOT NULL, metric_value TEXT, evidence_status TEXT NOT NULL, updated_at TEXT NOT NULL, notes TEXT);
INSERT INTO chronic_care VALUES ('CHR-6601', 'EHC-6601', 'engaged', 'current_engagement', '2026-08-10', 'Cycle record 1');
INSERT INTO chronic_care VALUES ('CHR-6602', 'EHC-6602', 'engaged', 'current_engagement', '2026-08-10', 'Cycle record 2');
INSERT INTO chronic_care VALUES ('CHR-6603', 'EHC-6603', 'engaged', 'current_engagement', '2026-08-10', 'Cycle record 3');
INSERT INTO chronic_care VALUES ('CHR-6604', 'EHC-6604', 'engaged', 'current_engagement', '2026-08-10', 'Cycle record 4');
INSERT INTO chronic_care VALUES ('CHR-6605', 'EHC-6605', 'engaged', 'current_engagement', '2026-08-10', 'Cycle record 5');
INSERT INTO chronic_care VALUES ('CHR-6606', 'EHC-6606', 'paused', 'participation_paused', '2026-08-10', 'Cycle record 6');
INSERT INTO chronic_care VALUES ('CHR-6607', 'EHC-6607', 'referral_pending', 'referral_pending', '2026-08-10', 'Cycle record 7');
INSERT INTO chronic_care VALUES ('CHR-6608', 'EHC-6608', 'unreported', 'outcome_unreported', '2026-08-10', 'Cycle record 8');
