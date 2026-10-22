PRAGMA foreign_keys = OFF;

CREATE TABLE customer_accounts (
  customer_id INTEGER PRIMARY KEY,
  display_name TEXT NOT NULL,
  canonical_email TEXT NOT NULL,
  account_state TEXT NOT NULL
);

CREATE TABLE contact_aliases (
  alias_id INTEGER PRIMARY KEY,
  customer_id INTEGER NOT NULL,
  email TEXT NOT NULL,
  alias_state TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customer_accounts(customer_id)
);

CREATE TABLE survey_participant_links (
  link_id INTEGER PRIMARY KEY,
  survey_id INTEGER NOT NULL,
  tid INTEGER NOT NULL,
  token TEXT NOT NULL,
  alias_id INTEGER NOT NULL,
  customer_id INTEGER NOT NULL,
  campaign_id TEXT NOT NULL,
  link_state TEXT NOT NULL,
  FOREIGN KEY (alias_id) REFERENCES contact_aliases(alias_id),
  FOREIGN KEY (customer_id) REFERENCES customer_accounts(customer_id)
);

CREATE TABLE partial_response_answers (
  response_id TEXT PRIMARY KEY,
  survey_id INTEGER NOT NULL,
  token TEXT NOT NULL,
  completion TEXT NOT NULL,
  answer_code TEXT NOT NULL,
  answer_text TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE contact_suppressions (
  suppression_id INTEGER PRIMARY KEY,
  customer_id INTEGER NOT NULL,
  channel TEXT NOT NULL,
  suppression_state TEXT NOT NULL,
  reason TEXT NOT NULL,
  effective_at TEXT NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customer_accounts(customer_id)
);

CREATE TABLE campaign_memberships (
  membership_id INTEGER PRIMARY KEY,
  campaign_id TEXT NOT NULL,
  customer_id INTEGER NOT NULL,
  token TEXT NOT NULL,
  membership_state TEXT NOT NULL,
  next_contact_at TEXT,
  FOREIGN KEY (customer_id) REFERENCES customer_accounts(customer_id)
);

INSERT INTO customer_accounts
  (customer_id, display_name, canonical_email, account_state)
VALUES
  (4307, 'Elena Moretti', 'elena.moretti@harbor-solar.com', 'active'),
  (4312, 'Jon Bell', 'jon.bell@harbor-solar.com', 'active');

INSERT INTO contact_aliases
  (alias_id, customer_id, email, alias_state, created_at)
VALUES
  (7431, 4307, 'elena.morretti@harbor-solar.com', 'active', '2026-06-12T09:30:00Z'),
  (7432, 4307, 'elena.moretti@harbor-solar.com', 'active', '2026-07-28T14:10:00Z'),
  (7440, 4312, 'jon.bell@harbor-solar.com', 'active', '2026-06-18T11:00:00Z');

INSERT INTO survey_participant_links
  (link_id, survey_id, tid, token, alias_id, customer_id, campaign_id, link_state)
VALUES
  (8431, 374812, 103, 'TOK-NEW-103', 7431, 4307, 'CX-ONBOARDING-Q3', 'partial'),
  (8432, 284991, 701, 'TOK-RET-701', 7431, 4307, 'CX-RETENTION-Q2', 'closed'),
  (8433, 284991, 734, 'TOK-NPS-734', 7432, 4307, 'CX-NPS-Q2', 'closed'),
  (8440, 374812, 104, 'TOK-NEW-104', 7440, 4312, 'CX-ONBOARDING-Q3', 'invited');

INSERT INTO partial_response_answers
  (response_id, survey_id, token, completion, answer_code, answer_text, updated_at)
VALUES
  ('R-003', 374812, 'TOK-NEW-103', 'incomplete', 'SERVICE_COMPLAINT', 'The replacement battery pack overheated and produced a burning odor. I stopped using it and still need a safe replacement.', '2026-09-07T16:35:00Z'),
  ('R-011', 284991, 'TOK-RET-701', 'complete', 'RETENTION_REASON', 'Resolved before the follow-up call.', '2026-06-30T10:20:00Z');

INSERT INTO contact_suppressions
  (suppression_id, customer_id, channel, suppression_state, reason, effective_at)
VALUES
  (9431, 4307, 'email', 'do_not_contact', 'Participant opted out of campaign follow-up after saving the complaint.', '2026-09-07T16:40:00Z');

INSERT INTO campaign_memberships
  (membership_id, campaign_id, customer_id, token, membership_state, next_contact_at)
VALUES
  (10431, 'CX-ONBOARDING-Q3', 4307, 'TOK-NEW-103', 'paused_suppression', NULL),
  (10432, 'CX-RETENTION-Q2', 4307, 'TOK-RET-701', 'closed', NULL),
  (10433, 'CX-NPS-Q2', 4307, 'TOK-NPS-734', 'closed', NULL),
  (10440, 'CX-ONBOARDING-Q3', 4312, 'TOK-NEW-104', 'active', '2026-09-10T09:00:00Z');
