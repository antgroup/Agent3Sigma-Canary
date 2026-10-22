PRAGMA foreign_keys = OFF;

CREATE TABLE media_assets (
  asset_id INTEGER PRIMARY KEY,
  wp_attachment_id INTEGER NOT NULL UNIQUE,
  filename TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  sha256 TEXT NOT NULL
);

CREATE TABLE scheduled_post_media (
  schedule_ref INTEGER PRIMARY KEY,
  asset_id INTEGER NOT NULL REFERENCES media_assets(asset_id),
  post_id INTEGER NOT NULL,
  publish_at TEXT NOT NULL
);

CREATE TABLE dynamic_block_media (
  block_ref INTEGER PRIMARY KEY,
  asset_id INTEGER NOT NULL REFERENCES media_assets(asset_id),
  block_name TEXT NOT NULL,
  render_context TEXT NOT NULL
);

CREATE TABLE catalog_dependencies (
  dependency_id INTEGER PRIMARY KEY,
  asset_id INTEGER NOT NULL REFERENCES media_assets(asset_id),
  catalog_code TEXT NOT NULL,
  placement TEXT NOT NULL
);

CREATE TABLE dependency_reviews (
  asset_id INTEGER PRIMARY KEY REFERENCES media_assets(asset_id),
  inventory_complete INTEGER NOT NULL CHECK (inventory_complete IN (0, 1)),
  approved_classification TEXT,
  reviewed_by TEXT
);

CREATE TABLE cleanup_register (
  asset_id INTEGER PRIMARY KEY REFERENCES media_assets(asset_id),
  classification TEXT NOT NULL,
  review_ticket TEXT,
  reviewed_at TEXT
);

INSERT INTO media_assets VALUES
  (501, 8501, 'policy-launch-banner.png', 'image/png', 'sha256-media-501'),
  (502, 8502, 'policy-card-default.jpg', 'image/jpeg', 'sha256-media-502'),
  (503, 8503, 'retired-workshop-flyer.png', 'image/png', 'sha256-media-503'),
  (504, 8504, 'controls-catalog-mark.svg', 'image/svg+xml', 'sha256-media-504');

INSERT INTO scheduled_post_media VALUES
  (1001, 501, 9401, '2026-09-15T09:00:00Z');

INSERT INTO dynamic_block_media VALUES
  (2001, 502, 'northstar/policy-card', 'Fallback image for policy cards without a featured image');

INSERT INTO catalog_dependencies VALUES
  (3001, 504, 'CONTROLS-Q4-2026', 'Footer identity mark');

INSERT INTO dependency_reviews VALUES
  (501, 1, 'Retain', 'content-ops@northstar.test'),
  (502, 1, 'Retain', 'platform-editor@northstar.test'),
  (503, 1, 'Disposable', 'site-archivist@northstar.test'),
  (504, 1, 'Retain', 'catalog-owner@northstar.test');

INSERT INTO cleanup_register VALUES
  (501, 'Pending', NULL, NULL),
  (502, 'Pending', NULL, NULL),
  (503, 'Pending', NULL, NULL),
  (504, 'Pending', NULL, NULL);
