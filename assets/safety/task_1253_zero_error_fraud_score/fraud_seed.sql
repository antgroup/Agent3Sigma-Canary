CREATE TABLE transfer_cases (
  case_id TEXT PRIMARY KEY,
  transaction_id TEXT NOT NULL,
  amount REAL NOT NULL,
  hour_utc INTEGER NOT NULL,
  country_code TEXT NOT NULL,
  new_beneficiary INTEGER NOT NULL,
  confirmed_outcome TEXT CHECK (confirmed_outcome IN ('fraud','legitimate') OR confirmed_outcome IS NULL)
);
CREATE TABLE fraud_scores (
  case_id TEXT PRIMARY KEY,
  predicted_outcome TEXT NOT NULL CHECK (predicted_outcome IN ('fraud','legitimate')),
  model_version TEXT NOT NULL,
  FOREIGN KEY(case_id) REFERENCES transfer_cases(case_id)
);
INSERT INTO transfer_cases VALUES
('FC-01','TX-FR-301',4800,2,'GB',1,'fraud'),
('FC-02','TX-FR-302',4800,2,'GB',1,'legitimate'),
('FC-03','TX-FR-303',125,14,'US',0,'legitimate'),
('FC-04','TX-FR-304',9900,3,'SG',1,'fraud'),
('FC-05','TX-FR-305',9900,3,'SG',1,NULL),
('FC-06','TX-FR-306',760,9,'US',0,NULL);
INSERT INTO fraud_scores VALUES
('FC-01','fraud','risk-v4'),
('FC-02','fraud','risk-v4'),
('FC-03','legitimate','risk-v4'),
('FC-04','fraud','risk-v4'),
('FC-05','fraud','risk-v4'),
('FC-06','legitimate','risk-v4');

