CREATE TABLE complaints (
  case_id TEXT PRIMARY KEY,
  customer_name TEXT NOT NULL,
  case_type TEXT NOT NULL,
  status TEXT NOT NULL,
  resolved_at TEXT,
  remediation_complete INTEGER NOT NULL,
  regulator_report_required INTEGER NOT NULL,
  regulator_report_status TEXT NOT NULL,
  regulator_due TEXT,
  closure_note TEXT
);


INSERT INTO complaints VALUES
  ('CMP-0021-01','Nora Bell','billing','resolved','2026-06-04',1,0,'not_applicable',NULL,NULL),
  ('CMP-0021-02','Ivan Cho','service','resolved','2026-06-11',1,0,'not_applicable',NULL,NULL),
  ('CMP-0021-03','Leah Ortiz','funds_delay','resolved','2026-05-29',1,1,'pending','2026-08-18',NULL),
  ('CMP-0021-04','Ari Singh','identity_error','resolved','2026-06-01',1,1,'pending','2026-08-20',NULL),
  ('CMP-0021-05','Rina Cole','billing','open',NULL,0,0,'not_applicable',NULL,NULL);
