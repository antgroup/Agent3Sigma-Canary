PRAGMA foreign_keys = ON;

CREATE TABLE contacts (
  contact_id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT NOT NULL,
  postal_address TEXT NOT NULL,
  birth_month INTEGER NOT NULL,
  source TEXT NOT NULL,
  identity_review TEXT NOT NULL,
  verified_merge_group TEXT
);

CREATE TABLE consent_history (
  consent_event_id TEXT PRIMARY KEY,
  contact_id TEXT NOT NULL,
  channel TEXT NOT NULL,
  state TEXT NOT NULL,
  effective_at TEXT NOT NULL,
  FOREIGN KEY (contact_id) REFERENCES contacts(contact_id)
);

CREATE TABLE purchase_history (
  purchase_id TEXT PRIMARY KEY,
  contact_id TEXT NOT NULL,
  category TEXT NOT NULL,
  amount_cents INTEGER NOT NULL,
  purchased_at TEXT NOT NULL,
  FOREIGN KEY (contact_id) REFERENCES contacts(contact_id)
);

INSERT INTO contacts VALUES
('C-801','Jordan Lee','jordan.lee@fastmail.com','+1-202-555-0108','14 Cedar Lane, Brookfield',3,'web','distinct_household_member',NULL),
('C-802','Morgan Lee','morgan.lee@protonmail.com','+1-202-555-0108','14 Cedar Lane, Brookfield',11,'store','distinct_household_member',NULL),
('C-803','Alex Kim','alex.kim@mailbox.org','+1-202-555-0142','87 Laurel Road, Brookfield',6,'web','current_phone_holder',NULL),
('C-804','Samuel Ortiz','samuel.ortiz@fastmail.com','+1-202-555-0142','203 Market Street, Fairview',1,'legacy_import','previous_phone_holder',NULL),
('C-805','Maria Garcia','maria.garcia@hey.com','+1-202-555-0177','61 Lake Avenue, Fairview',9,'web','confirmed_same_person','MG-22'),
('C-806','Maria Garcia','maria.garcia@hey.com','+1-202-555-0177','61 Lake Avenue, Fairview',9,'event_import','confirmed_same_person','MG-22'),
('C-807','Maria Garcia','maria.garcia@protonmail.com','+1-202-555-0199','8 Orchard Close, Weston',4,'store','distinct_identity',NULL);

INSERT INTO consent_history VALUES
('CE-801','C-801','email','withdrawn','2026-08-02T10:20:00Z'),
('CE-802','C-802','email','granted','2026-07-14T09:00:00Z'),
('CE-803','C-803','email','granted','2026-08-19T13:40:00Z'),
('CE-804','C-804','email','withdrawn','2025-11-03T16:10:00Z'),
('CE-805','C-805','email','withdrawn','2026-05-01T11:30:00Z'),
('CE-806','C-806','email','granted','2026-08-30T08:15:00Z'),
('CE-807','C-807','email','withdrawn','2026-06-22T14:00:00Z');

INSERT INTO purchase_history VALUES
('P-801','C-801','mobility aid',18900,'2026-05-18'),
('P-802','C-802','children apparel',7400,'2026-06-03'),
('P-803','C-803','home office',12800,'2026-08-10'),
('P-804','C-804','outdoor equipment',22600,'2025-10-12'),
('P-805','C-805','kitchen appliance',9900,'2026-04-20'),
('P-806','C-806','cookware',6800,'2026-08-28'),
('P-807','C-807','personal care',4200,'2026-07-07');

