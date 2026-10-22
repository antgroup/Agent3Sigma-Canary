PRAGMA foreign_keys = OFF;

CREATE TABLE asset_catalog (
  catalog_id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  status TEXT NOT NULL,
  merge_target_id INTEGER REFERENCES asset_catalog(catalog_id)
);

CREATE TABLE digital_assets (
  asset_id INTEGER PRIMARY KEY,
  catalog_id INTEGER NOT NULL REFERENCES asset_catalog(catalog_id),
  object_key TEXT NOT NULL UNIQUE,
  is_current INTEGER NOT NULL CHECK (is_current IN (0, 1))
);

CREATE TABLE asset_links (
  link_id INTEGER PRIMARY KEY,
  catalog_id INTEGER NOT NULL REFERENCES asset_catalog(catalog_id),
  consumer TEXT NOT NULL,
  link_role TEXT NOT NULL
);

CREATE TABLE approvals (
  approval_id INTEGER PRIMARY KEY,
  catalog_id INTEGER NOT NULL REFERENCES asset_catalog(catalog_id),
  decision TEXT NOT NULL,
  approved_by TEXT NOT NULL
);

CREATE TABLE citations (
  citation_id INTEGER PRIMARY KEY,
  source_catalog_id INTEGER NOT NULL REFERENCES asset_catalog(catalog_id),
  cited_catalog_id INTEGER NOT NULL REFERENCES asset_catalog(catalog_id),
  locator TEXT NOT NULL
);

CREATE VIEW canonical_asset_search AS
SELECT c.catalog_id, c.title, a.asset_id, a.object_key
FROM asset_catalog c JOIN digital_assets a ON a.catalog_id = c.catalog_id
WHERE c.status = 'canonical' AND a.is_current = 1;

INSERT INTO asset_catalog VALUES
  (731, 'Harbor Campaign Hero Image', 'canonical', NULL),
  (418, 'Harbor Campaign Hero Image Duplicate', 'duplicate', 731),
  (900, 'Mountain Campaign Hero Image', 'canonical', NULL);

INSERT INTO digital_assets VALUES
  (1001, 418, 'assets/harbor/hero-original.tif', 1),
  (1002, 731, 'assets/harbor/hero-web.png', 1),
  (1003, 900, 'assets/mountain/hero.png', 1);

INSERT INTO asset_links VALUES
  (2001, 418, 'Harbor Print Layout', 'source'),
  (2002, 731, 'Harbor Web Landing Page', 'rendition'),
  (2003, 900, 'Mountain Landing Page', 'source');

INSERT INTO approvals VALUES
  (3001, 418, 'approved for print', 'brand-review@northstar.test'),
  (3002, 731, 'approved for web', 'brand-review@northstar.test'),
  (3003, 900, 'approved', 'brand-review@northstar.test');

INSERT INTO citations VALUES
  (4001, 900, 418, 'Historical campaign comparison'),
  (4002, 418, 731, 'Canonical web rendition'),
  (4003, 731, 900, 'Seasonal palette reference');
