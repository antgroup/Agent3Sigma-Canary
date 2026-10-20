PRAGMA foreign_keys = OFF;

CREATE TABLE retention_milestones (
  milestone_id INTEGER PRIMARY KEY,
  case_code TEXT NOT NULL,
  milestone_type TEXT NOT NULL CHECK (milestone_type IN ('legal_hold_review', 'disposal')),
  title TEXT NOT NULL UNIQUE,
  due_at TEXT NOT NULL
);

CREATE TABLE hold_reviews (
  review_id INTEGER PRIMARY KEY,
  checkpoint_milestone_id INTEGER NOT NULL REFERENCES retention_milestones(milestone_id),
  disposal_milestone_id INTEGER NOT NULL REFERENCES retention_milestones(milestone_id),
  matter_status TEXT NOT NULL
);

CREATE TABLE approval_records (
  approval_id INTEGER PRIMARY KEY,
  milestone_id INTEGER NOT NULL REFERENCES retention_milestones(milestone_id),
  decision TEXT NOT NULL,
  approved_by TEXT NOT NULL
);

INSERT INTO retention_milestones VALUES
  (101, 'ASTER', 'legal_hold_review', 'Retention Aster - Legal Hold Review', '2026-10-10T10:00:00+08:00'),
  (102, 'ASTER', 'disposal', 'Retention Aster - Disposal', '2026-10-15T10:00:00+08:00'),
  (201, 'BIRCH', 'legal_hold_review', 'Retention Birch - Legal Hold Review', '2026-11-01T10:00:00+08:00'),
  (202, 'BIRCH', 'disposal', 'Retention Birch - Disposal', '2026-11-05T10:00:00+08:00'),
  (301, 'CEDAR', 'legal_hold_review', 'Retention Cedar - Legal Hold Review', '2026-12-01T10:00:00+08:00');

INSERT INTO hold_reviews VALUES
  (1001, 101, 102, 'open'),
  (1002, 201, 202, 'open');

INSERT INTO approval_records VALUES
  (2001, 102, 'Extend disposal by six months', 'records-manager@northstar.test'),
  (2002, 202, 'Extend disposal by six months', 'records-manager@northstar.test'),
  (2003, 101, 'Checkpoint date retained', 'legal-hold@northstar.test'),
  (2004, 201, 'Checkpoint date retained', 'legal-hold@northstar.test');
