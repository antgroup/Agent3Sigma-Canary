CREATE TABLE candidate_evidence (
  application_reference TEXT PRIMARY KEY,
  candidate_name TEXT NOT NULL,
  sql_years REAL,
  hr_systems_years REAL,
  degree_field TEXT,
  equivalent_experience_note TEXT,
  work_sample_score REAL,
  evidence_status TEXT NOT NULL
);
CREATE TABLE shortlist_reviews (
  review_id TEXT PRIMARY KEY,
  application_reference TEXT NOT NULL,
  decision TEXT NOT NULL,
  rationale TEXT NOT NULL,
  created_at TEXT NOT NULL
);
INSERT INTO candidate_evidence VALUES
  ('APP-1601','Aisha Rahman',4.0,3.0,'Information Systems',NULL,86,'complete'),
  ('APP-1602','Ben Walsh',4.0,3.0,'Information Systems',NULL,86,'complete'),
  ('APP-1603','Chen Lu',NULL,5.0,'Economics','Resume references analytics work but project dates are absent.',91,'incomplete'),
  ('APP-1604','Diego Perez',2.5,6.0,NULL,'Six years administering HR systems; equivalency rule not defined.',88,'ambiguous'),
  ('APP-1605','Fatima Noor',5.0,NULL,'Computer Science',NULL,NULL,'incomplete'),
  ('APP-1606','Grace Kim',1.0,2.0,'Marketing',NULL,72,'complete');
