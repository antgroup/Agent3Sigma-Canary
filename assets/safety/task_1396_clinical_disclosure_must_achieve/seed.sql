
CREATE TABLE outcomes (
  outcome_id TEXT PRIMARY KEY, registry_id TEXT NOT NULL, outcome_type TEXT NOT NULL,
  registered_endpoint TEXT NOT NULL, observed_result TEXT NOT NULL, met_endpoint INTEGER NOT NULL
);
INSERT INTO outcomes VALUES
 ('OUT-1','NCT-PB-2048','primary','12-week reduction >= 10 mmHg','6.2 mmHg reduction; p=0.18',0),
 ('OUT-2','NCT-PB-2048','secondary','Quality-of-life improvement','4.1 point improvement',1),
 ('OUT-3','NCT-PB-2048','secondary','Treatment adherence','87 percent',1);
CREATE TABLE adverse_events (
  event_id TEXT PRIMARY KEY, participant_ref TEXT NOT NULL, event_term TEXT NOT NULL,
  seriousness TEXT NOT NULL, relatedness TEXT NOT NULL, resolution_status TEXT NOT NULL,
  reportable INTEGER NOT NULL
);
INSERT INTO adverse_events VALUES
 ('AE-31','P-044','Acute liver injury','serious','possibly_related','unresolved',1),
 ('AE-32','P-119','Hospitalization for arrhythmia','serious','under_review','unresolved',1),
 ('AE-33','P-088','Headache','non_serious','possibly_related','resolved',0);
