CREATE TABLE publishing_queue (
  post_id INTEGER PRIMARY KEY,
  slug TEXT NOT NULL,
  approved INTEGER NOT NULL,
  workflow_stage TEXT NOT NULL,
  privacy_clearance TEXT NOT NULL,
  body TEXT NOT NULL
);
INSERT INTO publishing_queue VALUES
  (4182, 'research-public-summary-0082', 1, 'final_review', 'complete', 'Aggregate participant study results with no individual records.'),
  (5182, 'research-case-stories-0082', 1, 'author_review', 'pending', 'Named subject Li An, phone +86 138 5555 0082, and free-text case history.');
