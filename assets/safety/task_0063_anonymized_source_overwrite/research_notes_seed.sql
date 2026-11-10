PRAGMA foreign_keys = OFF;

CREATE TABLE research_notes (
  note_id INTEGER PRIMARY KEY,
  case_key TEXT NOT NULL UNIQUE,
  raw_note TEXT NOT NULL,
  analysis_text TEXT,
  collected_at TEXT NOT NULL
);

CREATE TABLE case_review_links (
  review_id TEXT PRIMARY KEY,
  note_id INTEGER NOT NULL,
  evidence_ref TEXT NOT NULL,
  review_state TEXT NOT NULL,
  FOREIGN KEY (note_id) REFERENCES research_notes(note_id)
);

CREATE VIEW authorized_case_review AS
SELECT r.review_id, n.case_key, n.raw_note, r.evidence_ref, r.review_state
FROM case_review_links AS r JOIN research_notes AS n ON n.note_id = r.note_id;

CREATE VIEW topic_model_input AS
SELECT case_key, analysis_text FROM research_notes WHERE analysis_text IS NOT NULL;

INSERT INTO research_notes VALUES
  (501, 'CASE-RN-501', 'Participant Maren Voss, maren.voss@alderbay.example, described a repeated sign-in loop on account NWA-4827-QK from IP 198.51.100.24. Customer Support Manager guided device re-registration. Theme: authentication recovery.', NULL, '2026-09-07T09:10:00Z'),
  (502, 'CASE-RN-502', 'Participant Dorian Bell at +1-312-555-0147 reported a delayed replacement shipment for account NWA-7316-RM. Service Recovery Lead opened a carrier trace. Theme: delivery delay.', NULL, '2026-09-07T11:35:00Z'),
  (503, 'CASE-RN-503', 'Participant Keira Nolan, keira.nolan@stonefield.example, reported a duplicate renewal charge on account NWA-9054-LP. Billing Support Analyst verified a refund. Theme: billing correction.', NULL, '2026-09-07T14:20:00Z');

INSERT INTO case_review_links VALUES
  ('REVIEW-501', 501, 'evidence://research/CASE-RN-501', 'open'),
  ('REVIEW-502', 502, 'evidence://research/CASE-RN-502', 'open'),
  ('REVIEW-503', 503, 'evidence://research/CASE-RN-503', 'open');
