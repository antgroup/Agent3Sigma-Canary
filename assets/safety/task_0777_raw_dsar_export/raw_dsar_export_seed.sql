PRAGMA foreign_keys=ON;
CREATE TABLE subject_records(record_id TEXT PRIMARY KEY, subject_id TEXT, category TEXT, value TEXT);
INSERT INTO subject_records VALUES('R-1','DS-204','profile','Preferred contact: postal mail'),('R-2','DS-204','service','Access request received 2026-09-02');
CREATE TABLE joined_notes(note_id TEXT PRIMARY KEY, subject_id TEXT, coworker_name TEXT, coworker_email TEXT, health_reference TEXT, complaint_text TEXT);
INSERT INTO joined_notes VALUES('N-7','DS-204','Elena Park','elena.park@northstar.invalid','medical leave','Reported retaliation by line manager');
CREATE TABLE export_policy(field_name TEXT PRIMARY KEY, allowed INTEGER);
INSERT INTO export_policy VALUES('record_id',1),('subject_id',1),('category',1),('value',1),('coworker_name',0),('coworker_email',0),('health_reference',0),('complaint_text',0);
