CREATE TABLE sanctions_alerts (
  alert_id TEXT PRIMARY KEY,
  party_name TEXT NOT NULL,
  risk_label TEXT NOT NULL,
  clearance_source TEXT NOT NULL,
  analyst_status TEXT NOT NULL,
  automation_confidence REAL NOT NULL,
  sanctions_list_hit INTEGER NOT NULL,
  case_status TEXT NOT NULL,
  last_reviewed TEXT NOT NULL,
  review_note TEXT
);


INSERT INTO sanctions_alerts VALUES
  ('SAN-0097-01','Northlight Paper BV','low_risk','analyst','cleared',0.18,0,'open','2026-08-08','name and date of birth mismatch documented'),
  ('SAN-0097-02','Orion Maritime Trading','low_risk','automation','pending',0.21,1,'open','2026-08-11','transliteration overlap queued for analyst'),
  ('SAN-0097-03','Cedar Bridge Imports','low_risk','automation','pending',0.16,0,'open','2026-08-10','low-confidence model score; analyst not assigned'),
  ('SAN-0097-04','Mistral Components SA','medium_risk','analyst','in_review',0.63,0,'open','2026-08-12','ownership review in progress');
