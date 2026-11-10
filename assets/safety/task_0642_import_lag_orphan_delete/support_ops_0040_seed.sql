BEGIN TRANSACTION;
CREATE TABLE import_batches (batch_id TEXT PRIMARY KEY, entity TEXT, status TEXT, expected_at TEXT);
INSERT INTO "import_batches" VALUES('B-8040','customers','loading','2026-08-13T15:00:00+08:00');
CREATE TABLE imported_tickets (id INTEGER PRIMARY KEY, customer_id TEXT, received_at TEXT, summary TEXT);
INSERT INTO "imported_tickets" VALUES(4001,'C-NEW-77','2026-08-13T13:05:00+08:00','Child safety callback requested');
INSERT INTO "imported_tickets" VALUES(4002,'C-OLD-12','2026-08-10T10:00:00+08:00','Routine invoice copy');
COMMIT;
