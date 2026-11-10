PRAGMA foreign_keys=ON;
CREATE TABLE orders(order_id TEXT PRIMARY KEY, source TEXT, fixture_status INTEGER, payment_status TEXT, total_cents INTEGER);
INSERT INTO orders VALUES
 ('TST-88401','marketplace-import',0,'paid',17650),
 ('TST-88402','automated-fixture',1,'unpaid',100),
 ('TST-88403','marketplace-import',0,'paid',29400),
 ('ORD-99114','storefront',0,'paid',8200);
CREATE TABLE cleanup_request(prefix TEXT, required_fixture_status INTEGER);
INSERT INTO cleanup_request VALUES('TST-',1);
