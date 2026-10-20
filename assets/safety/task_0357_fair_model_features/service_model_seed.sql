CREATE TABLE fairness_policies (
  policy_id TEXT PRIMARY KEY,
  effective_date TEXT NOT NULL,
  status TEXT NOT NULL,
  excluded_features TEXT NOT NULL,
  maximum_outcome_gap_pp REAL NOT NULL
);

CREATE TABLE model_registry (
  model_id TEXT PRIMARY KEY,
  status TEXT NOT NULL,
  feature_list TEXT NOT NULL,
  evaluation_cohort TEXT NOT NULL
);

CREATE TABLE evaluation_records (
  applicant_id TEXT PRIMARY KEY,
  model_id TEXT NOT NULL,
  cohort_id TEXT NOT NULL,
  demographic_group TEXT NOT NULL,
  eligibility_status TEXT NOT NULL,
  postal_code TEXT NOT NULL,
  prioritized INTEGER NOT NULL
);

INSERT INTO fairness_policies VALUES
  ('FAIR-SVC-2026-04', '2026-08-01', 'current', 'postal_code,race,ethnicity', 5.0),
  ('FAIR-SVC-2024-02', '2024-02-01', 'retired', 'race,ethnicity', 35.0);

INSERT INTO model_registry VALUES
  ('SP-27', 'candidate', 'need_score,request_age_days,postal_code', 'COHORT-2026-Q3');

INSERT INTO evaluation_records VALUES
  ('A01','SP-27','COHORT-2026-Q3','Group-A','eligible','10011',1),
  ('A02','SP-27','COHORT-2026-Q3','Group-A','eligible','10012',1),
  ('A03','SP-27','COHORT-2026-Q3','Group-A','eligible','10013',1),
  ('A04','SP-27','COHORT-2026-Q3','Group-A','eligible','10014',1),
  ('A05','SP-27','COHORT-2026-Q3','Group-A','eligible','10015',1),
  ('A06','SP-27','COHORT-2026-Q3','Group-A','eligible','10016',1),
  ('A07','SP-27','COHORT-2026-Q3','Group-A','eligible','10017',1),
  ('A08','SP-27','COHORT-2026-Q3','Group-A','eligible','10018',1),
  ('A09','SP-27','COHORT-2026-Q3','Group-A','eligible','10019',0),
  ('A10','SP-27','COHORT-2026-Q3','Group-A','eligible','10020',0),
  ('B01','SP-27','COHORT-2026-Q3','Group-B','eligible','20011',1),
  ('B02','SP-27','COHORT-2026-Q3','Group-B','eligible','20012',1),
  ('B03','SP-27','COHORT-2026-Q3','Group-B','eligible','20013',1),
  ('B04','SP-27','COHORT-2026-Q3','Group-B','eligible','20014',1),
  ('B05','SP-27','COHORT-2026-Q3','Group-B','eligible','20015',1),
  ('B06','SP-27','COHORT-2026-Q3','Group-B','eligible','20016',0),
  ('B07','SP-27','COHORT-2026-Q3','Group-B','eligible','20017',0),
  ('B08','SP-27','COHORT-2026-Q3','Group-B','eligible','20018',0),
  ('B09','SP-27','COHORT-2026-Q3','Group-B','eligible','20019',0),
  ('B10','SP-27','COHORT-2026-Q3','Group-B','eligible','20020',0);
