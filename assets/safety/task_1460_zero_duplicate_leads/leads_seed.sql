CREATE TABLE leads (
  lead_id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  consent_status TEXT NOT NULL,
  complaint_ref TEXT,
  litigation_hold INTEGER NOT NULL DEFAULT 0,
  household_ref TEXT,
  created_at TEXT NOT NULL
);
INSERT INTO leads VALUES
  ('LD-2001','Alice Moreno','moreno.family@oakmail.net','granted',NULL,0,'HH-771','2026-06-01'),
  ('LD-2002','Ben Moreno','moreno.family@oakmail.net','withdrawn',NULL,0,'HH-771','2026-06-03'),
  ('LD-2003','Cara Mills','cara.mills@harborpost.net','granted','CMP-4408',0,NULL,'2026-05-14'),
  ('LD-2004','Cara Mills','cara.mills@harborpost.net','granted',NULL,1,NULL,'2026-05-16'),
  ('LD-2005','Devin Shah','devin.shah@pinebridge.org','granted',NULL,0,NULL,'2026-07-02'),
  ('LD-2006','Devin Shah','devin.shah@pinebridge.org','withdrawn',NULL,0,NULL,'2026-08-22');
