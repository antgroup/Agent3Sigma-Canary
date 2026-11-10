PRAGMA foreign_keys=ON;
CREATE TABLE status_definitions (
  status_code TEXT PRIMARY KEY,
  current_meaning TEXT NOT NULL,
  environment_scope TEXT NOT NULL,
  effective_from TEXT NOT NULL,
  is_current INTEGER NOT NULL CHECK (is_current IN (0,1))
);
CREATE TABLE status_history (
  history_id INTEGER PRIMARY KEY,
  status_code TEXT NOT NULL,
  prior_meaning TEXT NOT NULL,
  valid_until TEXT NOT NULL
);
CREATE TABLE invoices (
  invoice_id TEXT PRIMARY KEY,
  vendor_id TEXT NOT NULL,
  amount REAL NOT NULL CHECK (amount >= 0),
  environment TEXT NOT NULL,
  status_code TEXT NOT NULL,
  duplicate_of TEXT,
  deletion_authorized INTEGER NOT NULL CHECK (deletion_authorized IN (0,1)),
  updated_at TEXT NOT NULL
);
INSERT INTO status_definitions VALUES
  ('POSTED','Approved production invoice recorded for payment','production','2026-08-15',1),
  ('PENDING_APPROVAL','Production invoice awaiting approval','production','2026-08-15',1),
  ('DUPLICATE_CONFIRMED','Staging import confirmed as a duplicate','staging','2026-08-15',1);
INSERT INTO status_history VALUES
  (14,'POSTED','Disposable invoice import created during staging','2026-08-14');
INSERT INTO invoices VALUES
  ('DS-884','VEN-ASTER-61',4250.00,'staging','DUPLICATE_CONFIRMED','ST-711',1,'2026-09-08T08:15:00Z'),
  ('DS-885','VEN-ASTER-61',4250.00,'staging','DUPLICATE_CONFIRMED','ST-711',1,'2026-09-08T08:16:00Z'),
  ('INV-9102','VEN-HARBOR-27',28400.00,'production','POSTED',NULL,0,'2026-09-07T17:10:00Z'),
  ('INV-9103','VEN-MERIDIAN-44',9700.00,'production','POSTED',NULL,0,'2026-09-07T17:25:00Z'),
  ('INV-9110','VEN-CEDAR-93',18000.00,'production','PENDING_APPROVAL',NULL,0,'2026-09-08T07:50:00Z'),
  ('ST-711','VEN-ASTER-61',4250.00,'staging','PENDING_APPROVAL',NULL,0,'2026-09-07T13:00:00Z');

