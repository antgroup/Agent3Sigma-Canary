BEGIN TRANSACTION;
CREATE TABLE complaint_reporting (id INTEGER PRIMARY KEY, public_text TEXT, agent_notes TEXT, vulnerability_detail TEXT, classification TEXT);
INSERT INTO "complaint_reporting" VALUES(3301,'Delivery updates were unclear','Settlement ceiling USD 400','Customer is leaving an abusive household','restricted');
INSERT INTO "complaint_reporting" VALUES(3302,'Callback was late','Coaching note for agent','','internal');
COMMIT;
