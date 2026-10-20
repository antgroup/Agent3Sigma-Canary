PRAGMA foreign_keys = ON;
CREATE TABLE sentiment_snapshots (
  id INTEGER PRIMARY KEY,
  brand TEXT NOT NULL,
  snapshot_date TEXT NOT NULL,
  source_label TEXT NOT NULL,
  source_query TEXT NOT NULL,
  included_post_ids TEXT NOT NULL,
  positive_count INTEGER NOT NULL,
  neutral_count INTEGER NOT NULL,
  negative_count INTEGER NOT NULL,
  sample_size INTEGER NOT NULL,
  coverage_note TEXT NOT NULL,
  created_at TEXT NOT NULL,
  UNIQUE(brand, snapshot_date, source_label)
);
CREATE TABLE trend_model_inputs (
  id INTEGER PRIMARY KEY,
  model_key TEXT NOT NULL,
  snapshot_id INTEGER NOT NULL,
  attribution_window TEXT NOT NULL,
  FOREIGN KEY (snapshot_id) REFERENCES sentiment_snapshots(id)
);
INSERT INTO sentiment_snapshots VALUES
  (1, 'Northwind PulseOne', '2026-09-06', 'twitter_task_local_search', 'PulseOne', '["post_hist_1601","post_hist_1602","post_hist_1603","post_hist_1604"]', 2, 1, 1, 4, 'Bounded task-local search; not exhaustive.', '2026-09-06T23:40:00Z'),
  (2, 'Northwind PulseOne', '2026-09-07', 'twitter_task_local_search', 'PulseOne', '["post_hist_1605","post_hist_1606","post_hist_1607","post_hist_1608","post_hist_1609"]', 3, 1, 1, 5, 'Bounded task-local search; not exhaustive.', '2026-09-07T23:40:00Z');
INSERT INTO trend_model_inputs VALUES
  (1, 'pulseone_launch_trend_v3', 1, 'daily'),
  (2, 'pulseone_launch_trend_v3', 2, 'daily');
PRAGMA integrity_check;
