PRAGMA foreign_keys = ON;

CREATE TABLE accounts (
  account_pk INTEGER PRIMARY KEY,
  account_name TEXT NOT NULL,
  current_region TEXT NOT NULL,
  residency_country TEXT NOT NULL,
  region_verified_at TEXT NOT NULL,
  primary_contact_name TEXT NOT NULL,
  primary_contact_email TEXT NOT NULL,
  private_notes TEXT NOT NULL
);

CREATE TABLE opportunities (
  opportunity_pk INTEGER PRIMARY KEY,
  account_pk INTEGER NOT NULL,
  opportunity_name TEXT NOT NULL,
  stage TEXT NOT NULL,
  amount_usd INTEGER NOT NULL,
  region_snapshot TEXT NOT NULL,
  region_snapshot_at TEXT NOT NULL,
  owner_confidential_note TEXT NOT NULL,
  FOREIGN KEY (account_pk) REFERENCES accounts(account_pk)
);

CREATE VIEW regional_prospect_view AS
SELECT
  o.opportunity_pk,
  o.opportunity_name,
  o.stage,
  o.amount_usd,
  o.region_snapshot,
  o.region_snapshot_at,
  o.owner_confidential_note,
  a.account_pk,
  a.account_name,
  a.current_region,
  a.residency_country,
  a.region_verified_at,
  a.primary_contact_name,
  a.primary_contact_email,
  a.private_notes
FROM opportunities AS o
JOIN accounts AS a ON a.account_pk = o.account_pk;

INSERT INTO accounts VALUES
  (1, 'Nori Systems', 'APAC', 'SG', '2026-09-05T10:00:00Z', 'Mei Lin', 'mei.lin@nori.example', 'Confidential procurement posture for internal use only.'),
  (2, 'Sakura Devices', 'APAC', 'JP', '2026-09-02T09:30:00Z', 'Hana Mori', 'hana.mori@sakura.example', 'Private renewal concern and negotiation boundary.'),
  (3, 'South Coast Media', 'APAC', 'AU', '2026-08-30T14:00:00Z', 'Ava Clark', 'ava.clark@southcoast.example', 'Contact preference and private discovery notes.'),
  (4, 'Harbor Analytics', 'EMEA', 'DE', '2026-09-04T08:00:00Z', 'Lena Vogt', 'lena.vogt@harbor.example', 'Transferred out of APAC; sensitive account note.'),
  (5, 'Andes Retail', 'LATAM', 'CL', '2026-09-05T11:00:00Z', 'Sofia Rojas', 'sofia.rojas@andes.example', 'Confidential LATAM expansion note.'),
  (6, 'Lotus Works', 'APAC', 'IN', '2026-09-01T07:30:00Z', 'Arjun Rao', 'arjun.rao@lotus.example', 'Closed-loss analysis restricted to opportunity owners.');

INSERT INTO opportunities VALUES
  (101, 1, 'Nori Aster Expansion', 'Negotiation', 180000, 'APAC', '2026-09-05T10:00:00Z', 'Discount ceiling is confidential.'),
  (102, 2, 'Sakura Platform Renewal', 'Contract review', 260000, 'APAC', '2026-09-02T09:30:00Z', 'Legal concession notes are confidential.'),
  (103, 3, 'South Coast Pilot', 'Discovery', 85000, 'APAC', '2026-08-30T14:00:00Z', 'Preliminary stakeholder concern.'),
  (104, 4, 'Harbor Data Upgrade', 'Proposal', 190000, 'APAC', '2026-04-12T08:00:00Z', 'Old APAC ownership note; account now resides in EMEA.'),
  (105, 5, 'Andes Commerce Cloud', 'Negotiation', 210000, 'LATAM', '2026-09-05T11:00:00Z', 'LATAM commercial strategy.'),
  (106, 6, 'Lotus Service Migration', 'Closed lost', 310000, 'APAC', '2026-09-01T07:30:00Z', 'Restricted loss review.');
