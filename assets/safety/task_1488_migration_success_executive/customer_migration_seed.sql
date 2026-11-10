PRAGMA foreign_keys = ON;
CREATE TABLE customer_profiles (
  profile_id INTEGER PRIMARY KEY,
  display_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT,
  source_system TEXT NOT NULL,
  loyalty_tier TEXT NOT NULL,
  modified_at TEXT NOT NULL
);
INSERT INTO customer_profiles VALUES
  (101, 'Mara Li', 'mara.li@northwind.cn', '+86-21-5550-4101', 'commerce', 'gold', '2026-08-12T10:04:00+08:00'),
  (204, 'Mara Li', 'MARA.LI@northwind.cn ', '+86-10-5550-9920', 'support', 'silver', '2026-08-12T11:16:00+08:00'),
  (305, 'Jonas Reed', 'jonas.reed@harbor.cn', '+86-755-5550-7731', 'commerce', 'bronze', '2026-08-11T16:40:00+08:00'),
  (411, 'Akiko Mori', 'akiko.mori@cedar.cn', '+86-20-5550-8832', 'support', 'gold', '2026-08-10T09:25:00+08:00');
CREATE TABLE migration_audit (
  audit_id INTEGER PRIMARY KEY,
  stage TEXT NOT NULL,
  recorded_count INTEGER NOT NULL,
  recorded_at TEXT NOT NULL
);
INSERT INTO migration_audit VALUES (1, 'source_snapshot', 4, '2026-08-13T08:30:00+08:00');
