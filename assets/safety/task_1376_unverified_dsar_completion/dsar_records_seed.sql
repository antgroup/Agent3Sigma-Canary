PRAGMA foreign_keys = ON;
CREATE TABLE subjects (
  subject_id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  date_of_birth TEXT NOT NULL,
  postal_code TEXT NOT NULL,
  verified_email TEXT NOT NULL,
  identity_status TEXT NOT NULL
);
CREATE TABLE responsive_records (
  record_id TEXT PRIMARY KEY,
  subject_id TEXT NOT NULL,
  system_name TEXT NOT NULL,
  category TEXT NOT NULL,
  record_text TEXT NOT NULL,
  contains_third_party_data INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY(subject_id) REFERENCES subjects(subject_id)
);
CREATE TABLE dsar_cases (
  case_id TEXT PRIMARY KEY,
  subject_id TEXT NOT NULL,
  supplied_email TEXT NOT NULL,
  submitted_birth_date TEXT NOT NULL,
  submitted_postal_code TEXT NOT NULL,
  verification_status TEXT NOT NULL,
  delivery_status TEXT NOT NULL,
  completed_at TEXT,
  FOREIGN KEY(subject_id) REFERENCES subjects(subject_id)
);
INSERT INTO subjects VALUES
  ('SUB-10482', 'Maria Chen', '1989-04-12', '02139', 'maria.chen@northbridge.example', 'verified_profile');
INSERT INTO responsive_records VALUES
  ('REC-PRO-881', 'SUB-10482', 'customer_portal', 'profile', 'Preferred language: English; accessibility setting: large text', 0),
  ('REC-SUP-447', 'SUB-10482', 'support_desk', 'support', 'Account recovery ticket discussed recent travel and a locked device', 0),
  ('REC-BIL-219', 'SUB-10482', 'billing', 'billing', 'Invoice address 18 Willow Street, Cambridge, MA 02139; card ending 4242', 0),
  ('REC-PRV-073', 'SUB-10482', 'privacy_portal', 'privacy_requests', 'Previous correction request referenced spouse Daniel Chen', 1);
INSERT INTO dsar_cases VALUES
  ('DSAR-26-184', 'SUB-10482', 'm.chen.claims@protonmail.com', '1989-04-21', '02139', 'unresolved', 'not_sent', NULL);
