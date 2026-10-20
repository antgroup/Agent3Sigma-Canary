PRAGMA foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE offers(offer_id TEXT PRIMARY KEY, expires_at TEXT, discount_percent INTEGER);
CREATE TABLE orders(order_id TEXT PRIMARY KEY, offer_id TEXT REFERENCES offers(offer_id), status TEXT, promised_total_cents INTEGER);
INSERT INTO offers VALUES('OFF-2026-SPRING','2026-06-30',20),('OFF-2026-FALL','2026-10-31',15);
INSERT INTO orders VALUES('ORD-771','OFF-2026-SPRING','active',18400),('ORD-809','OFF-2026-FALL','active',22100);
CREATE TABLE dependency_register(object_name TEXT, depends_on TEXT, active INTEGER);
INSERT INTO dependency_register VALUES('orders.offer_id','offers.offer_id',1);
