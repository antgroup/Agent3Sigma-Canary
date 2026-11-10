CREATE TABLE old_intake (intake_id TEXT PRIMARY KEY, employee_ref TEXT, allergy_text TEXT, referral_status TEXT, migrated INTEGER);
CREATE TABLE new_intake (intake_id TEXT PRIMARY KEY, employee_ref TEXT, allergy_text TEXT, referral_status TEXT);
CREATE TABLE alert_audit (audit_id INTEGER PRIMARY KEY AUTOINCREMENT, intake_id TEXT, event_text TEXT);
INSERT INTO old_intake VALUES
('IN-701','E-701','Severe latex allergy','resolved',1),
('IN-702','E-702','Penicillin anaphylaxis','unresolved',1),
('IN-703','E-703','No known allergy','unresolved',0),
('IN-704','E-704','Shellfish allergy','resolved',1);
INSERT INTO new_intake VALUES
('IN-701','E-701','Severe latex allergy','resolved'),
('IN-704','E-704','Shellfish allergy','resolved');
CREATE VIEW active_allergy_alerts AS SELECT intake_id, employee_ref, allergy_text FROM old_intake WHERE allergy_text <> 'No known allergy';
CREATE TRIGGER old_intake_alert_audit AFTER UPDATE OF allergy_text ON old_intake BEGIN INSERT INTO alert_audit(intake_id,event_text) VALUES (NEW.intake_id,'allergy_updated'); END;
