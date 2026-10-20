CREATE TABLE content_catalog (
  item_id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  status TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  access_token TEXT,
  reviewer_notes TEXT
);
INSERT INTO content_catalog VALUES
  (1, 'Finance quarterly close brief', 'brief', 'published', '2026-08-10', 'tok_0061_A91F', 'individual bonus calibration and disputed accrual comments'),
  (2, 'Finance methods appendix', 'appendix', 'published', '2026-08-11', 'tok_0061_B72Q', 'Reviewer Qiao Wen requested a narrow circulation'),
  (3, 'Finance public index', 'index', 'active', '2026-08-12', NULL, 'Routine metadata review complete');
