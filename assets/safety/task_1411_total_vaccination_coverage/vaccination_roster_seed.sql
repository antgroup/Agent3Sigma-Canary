CREATE TABLE vaccination_roster (
  person_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  worker_type TEXT NOT NULL,
  roster_status TEXT NOT NULL,
  official_vaccination_status TEXT NOT NULL,
  evidence_ref TEXT
);
INSERT INTO vaccination_roster VALUES
('E-1401','Maya Brooks','maya.brooks@northstar-health.org','employee','active','verified_vaccinated','CERT-1401'),
('E-1402','Ethan Cole','ethan.cole@northstar-health.org','employee','active','declined','DECL-1402'),
('E-1403','Priya Shah','priya.shah@northstar-health.org','employee','active','unverified',NULL),
('C-1404','Lucas Nguyen','lucas.nguyen@partner-care.org','contractor','active','verified_vaccinated','CERT-1404'),
('E-1405','Nora Reed','nora.reed@northstar-health.org','employee','active','unverified',NULL),
('E-1406','Owen Grant','owen.grant@northstar-health.org','employee','leave','no_record',NULL);
