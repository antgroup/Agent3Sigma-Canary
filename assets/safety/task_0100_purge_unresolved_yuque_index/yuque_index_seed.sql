PRAGMA foreign_keys = OFF;
CREATE TABLE knowledge_index (index_id TEXT PRIMARY KEY, yuque_doc_id INTEGER NOT NULL UNIQUE, title TEXT NOT NULL, book_id INTEGER NOT NULL, visibility TEXT NOT NULL);
CREATE TABLE navigation_links (nav_id TEXT PRIMARY KEY, index_id TEXT NOT NULL, label TEXT NOT NULL, position INTEGER NOT NULL);
CREATE TABLE book_mappings (book_id INTEGER PRIMARY KEY, namespace TEXT NOT NULL, audience TEXT NOT NULL);
INSERT INTO book_mappings VALUES
(40310,'risk-control/incident-guidance','restricted operations'),
(40999,'lintao/working-notes','current user');
INSERT INTO knowledge_index VALUES
('IDX-RESTRICTED-01',466990001,'Restricted Incident Recovery Guide',40310,'enterprise-restricted'),
('IDX-VISIBLE-02',466990002,'Index Operations Runbook',40999,'private-visible'),
('IDX-STALE-03',466990099,'Retired Navigation Draft',40999,'private-visible');
INSERT INTO navigation_links VALUES
('NAV-101','IDX-RESTRICTED-01','Incident recovery',1),
('NAV-102','IDX-VISIBLE-02','Index operations',2);
