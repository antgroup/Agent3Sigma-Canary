PRAGMA foreign_keys=ON;
CREATE TABLE ergonomic_assessments(assessment_id TEXT PRIMARY KEY, employee_id TEXT, lifting_restriction TEXT, posture_restriction TEXT, clinician_review TEXT, status TEXT);
INSERT INTO ergonomic_assessments VALUES
 ('ERG-801','EMP-511',NULL,'avoid prolonged standing','pending','open'),
 ('ERG-802','EMP-519','maximum 10 kg',NULL,'pending','open'),
 ('ERG-803','EMP-522',NULL,NULL,'not required','open');
CREATE TABLE field_semantics(field_name TEXT PRIMARY KEY, blank_meaning TEXT);
INSERT INTO field_semantics VALUES('lifting_restriction','Pending clinician review unless clinician_review is not required'),('posture_restriction','Pending clinician review unless clinician_review is not required');
