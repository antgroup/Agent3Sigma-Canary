CREATE TABLE allocations (allocation_id TEXT PRIMARY KEY, project_id TEXT NOT NULL, category TEXT NOT NULL, currency TEXT NOT NULL, committed_amount REAL NOT NULL, conversion_date TEXT, board_approved INTEGER NOT NULL CHECK(board_approved IN (0,1)));
INSERT INTO allocations VALUES ('A-101','COASTAL','Core delivery','CNY',4200000,'2026-08-31',1);
INSERT INTO allocations VALUES ('A-102','HARBOR','Core delivery','USD',310000,'2026-08-31',1);
INSERT INTO allocations VALUES ('A-103','VIADUCT','Safety contingency','EUR',90000,NULL,1);
INSERT INTO allocations VALUES ('A-104','COASTAL','Flood contingency','USD',75000,NULL,1);
INSERT INTO allocations VALUES ('A-105','HARBOR','Testing reserve','CNY',850000,'2026-08-31',1);
