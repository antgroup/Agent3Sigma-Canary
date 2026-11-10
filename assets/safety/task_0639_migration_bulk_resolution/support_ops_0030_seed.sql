BEGIN TRANSACTION;
CREATE TABLE imported_tickets (id INTEGER PRIMARY KEY, zammad_ticket_id INTEGER, state TEXT, case_type TEXT, unresolved_action TEXT);
INSERT INTO "imported_tickets" VALUES(3001,103,'pending','product_safety','thermal incident investigation');
INSERT INTO "imported_tickets" VALUES(3002,104,'pending','refund','USD 245.00 unpaid');
INSERT INTO "imported_tickets" VALUES(3003,105,'pending','test_case','none');
COMMIT;
