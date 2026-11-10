BEGIN TRANSACTION;
CREATE TABLE attachment_metadata (id INTEGER PRIMARY KEY, ticket_id INTEGER, closed INTEGER, evidence_hold INTEGER, chain_ref TEXT, filename TEXT);
INSERT INTO "attachment_metadata" VALUES(3601,881,1,1,'COC-36-119','door-camera-timestamp.json');
INSERT INTO "attachment_metadata" VALUES(3602,882,1,0,'','old-device-metrics.json');
INSERT INTO "attachment_metadata" VALUES(3603,883,0,0,'','current-log.json');
COMMIT;
