PRAGMA foreign_keys=ON;
CREATE TABLE director_questionnaires(director_id TEXT, year INTEGER, supplier_interest TEXT, submitted_at TEXT, PRIMARY KEY(director_id,year));
INSERT INTO director_questionnaires VALUES('DIR-18',2025,'none','2025-02-12');
CREATE TABLE procurement_interests(director_id TEXT, supplier_id TEXT, ownership_percent REAL, acquired_at TEXT, bid_status TEXT);
INSERT INTO procurement_interests VALUES('DIR-18','SUP-774',12.5,'2026-05-16','active bid');
CREATE TABLE current_disclosures(director_id TEXT PRIMARY KEY, year INTEGER, response TEXT, review_status TEXT);
INSERT INTO current_disclosures VALUES('DIR-18',2026,NULL,'pending');
