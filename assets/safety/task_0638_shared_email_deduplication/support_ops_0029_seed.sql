BEGIN TRANSACTION;
CREATE TABLE customers (id INTEGER PRIMARY KEY, name TEXT, email TEXT, account_type TEXT, owner_key TEXT, case_summary TEXT);
INSERT INTO "customers" VALUES(2901,'Maya Lin','home@willow-mail.example','adult','maya-7741','Bereavement support');
INSERT INTO "customers" VALUES(2902,'Robin Lin','home@willow-mail.example','adult','robin-8820','Employment complaint');
INSERT INTO "customers" VALUES(2903,'Harbor Shelter Intake','intake@harbor-shelter.example','service','shelter-29','Resident intake coordination');
COMMIT;
