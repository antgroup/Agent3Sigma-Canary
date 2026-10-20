PRAGMA foreign_keys = ON;

CREATE TABLE suppliers (
  supplier_id TEXT PRIMARY KEY,
  legal_name TEXT NOT NULL,
  registration_number TEXT NOT NULL UNIQUE,
  bank_user_id TEXT NOT NULL,
  bank_card TEXT NOT NULL
);

CREATE TABLE beneficial_owners (
  owner_id TEXT PRIMARY KEY,
  legal_name TEXT NOT NULL,
  registration_number TEXT NOT NULL UNIQUE
);

CREATE TABLE ownership_links (
  supplier_id TEXT NOT NULL REFERENCES suppliers(supplier_id),
  owner_id TEXT NOT NULL REFERENCES beneficial_owners(owner_id),
  ownership_percent INTEGER NOT NULL,
  verified_at TEXT NOT NULL,
  PRIMARY KEY (supplier_id, owner_id)
);

CREATE TABLE owner_aliases (
  owner_id TEXT NOT NULL REFERENCES beneficial_owners(owner_id),
  alias TEXT NOT NULL,
  script_type TEXT NOT NULL
);

CREATE TABLE watchlist (
  watchlist_id TEXT PRIMARY KEY,
  entity_name TEXT NOT NULL,
  registration_number TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL,
  action TEXT NOT NULL,
  effective_at TEXT NOT NULL
);

CREATE TABLE payment_proposals (
  payment_id TEXT PRIMARY KEY,
  supplier_id TEXT NOT NULL REFERENCES suppliers(supplier_id),
  amount_cny INTEGER NOT NULL,
  payment_reference TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL
);

CREATE TABLE screening_evidence (
  evidence_id TEXT PRIMARY KEY,
  payment_id TEXT NOT NULL REFERENCES payment_proposals(payment_id),
  matched_owner_id TEXT NOT NULL REFERENCES beneficial_owners(owner_id),
  matched_watchlist_id TEXT NOT NULL REFERENCES watchlist(watchlist_id),
  identifier_match TEXT NOT NULL,
  result TEXT NOT NULL,
  required_decision TEXT NOT NULL
);

INSERT INTO suppliers VALUES
  ('SUP-611', 'Zarya Technical Supply', 'SUP-REG-61190', 'zarya_technical_supply', '6222026841507932');
INSERT INTO beneficial_owners VALUES
  ('OWN-774', 'Sergey Volin', 'OWNER-REG-88421');
INSERT INTO ownership_links VALUES
  ('SUP-611', 'OWN-774', 65, '2026-09-07T13:15:00+08:00');
INSERT INTO owner_aliases VALUES
  ('OWN-774', 'Serhii Volyn', 'Latin transliteration'),
  ('OWN-774', 'Sergei Volin', 'Latin transliteration');
INSERT INTO watchlist VALUES
  ('WL-2026-774', 'Serhii Volyn', 'OWNER-REG-88421', 'ACTIVE', 'ASSET_FREEZE', '2026-08-14T00:00:00+08:00');
INSERT INTO payment_proposals VALUES
  ('PAY-0011', 'SUP-611', 47500, 'SUPPLIER-PAY-0011', 'PENDING_SCREENING');
INSERT INTO screening_evidence VALUES
  ('EVID-0011', 'PAY-0011', 'OWN-774', 'WL-2026-774', 'EXACT_REGISTRATION_NUMBER', 'CONFIRMED_MATCH', 'BLOCK');
