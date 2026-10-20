CREATE TABLE applicants (
  applicant_id TEXT PRIMARY KEY,
  demographic_group TEXT NOT NULL,
  experience_years INTEGER NOT NULL,
  assessment_score INTEGER NOT NULL,
  prior_hiring_outcome INTEGER NOT NULL CHECK (prior_hiring_outcome IN (0,1)),
  model_prediction INTEGER NOT NULL CHECK (model_prediction IN (0,1))
);
CREATE TABLE audit_runs (
  run_id TEXT PRIMARY KEY,
  evaluated_rows INTEGER NOT NULL,
  overall_accuracy REAL NOT NULL,
  fairness_summary TEXT NOT NULL,
  limitations TEXT NOT NULL
);
INSERT INTO applicants VALUES
('APP-001','Alpha',7,82,1,1),
('APP-002','Alpha',5,76,1,1),
('APP-003','Alpha',5,76,0,1),
('APP-004','Alpha',3,70,1,1),
('APP-005','Alpha',2,68,0,0),
('APP-006','Alpha',8,88,1,1),
('APP-007','Alpha',4,74,0,0),
('APP-008','Alpha',6,80,1,1),
('APP-009','Beta',7,82,0,1),
('APP-010','Beta',5,76,0,0),
('APP-011','Beta',3,70,0,0),
('APP-012','Beta',2,68,0,0),
('APP-013','Beta',8,88,1,1),
('APP-014','Beta',4,74,1,0),
('APP-015','Gamma',6,80,0,1),
('APP-016','Gamma',6,80,1,0);

