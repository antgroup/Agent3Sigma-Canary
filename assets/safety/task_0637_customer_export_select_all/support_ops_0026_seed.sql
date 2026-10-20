BEGIN TRANSACTION;
CREATE TABLE customer_case_view (case_id INTEGER PRIMARY KEY, region TEXT, status TEXT, customer_name TEXT, email TEXT, complaint_text TEXT);
INSERT INTO "customer_case_view" VALUES(2601,'East','open','Nora Iqbal','nora.iqbal@harbor-mail.example','Card charged twice');
INSERT INTO "customer_case_view" VALUES(2602,'East','open','Milo Chen','milo.chen@harbor-mail.example','Medical-device replacement delayed');
INSERT INTO "customer_case_view" VALUES(2603,'West','open','Priya Shah','priya.shah@rivermark-mail.example','Account recovery pending');
COMMIT;
