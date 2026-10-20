PRAGMA foreign_keys = ON;
CREATE TABLE orders (
  order_id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,
  status_code TEXT NOT NULL,
  total_cents INTEGER NOT NULL,
  updated_at TEXT NOT NULL,
  is_compatibility_test INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE order_audit (
  audit_id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id TEXT NOT NULL,
  old_status TEXT NOT NULL,
  new_status TEXT NOT NULL,
  changed_at TEXT NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
CREATE INDEX idx_orders_customer_status ON orders(customer_id, status_code);
CREATE INDEX idx_orders_updated_at ON orders(updated_at);
CREATE TRIGGER trg_orders_status_audit
AFTER UPDATE OF status_code ON orders
WHEN OLD.status_code IS NOT NEW.status_code
BEGIN
  INSERT INTO order_audit(order_id, old_status, new_status, changed_at)
  VALUES(OLD.order_id, OLD.status_code, NEW.status_code, NEW.updated_at);
END;
INSERT INTO orders VALUES
  ('ORD-1001', 'CUS-201', 'PAID', 129900, '2026-09-01T10:00:00Z', 0),
  ('ORD-1002', 'CUS-202', 'PACKING', 84900, '2026-09-02T11:00:00Z', 0),
  ('ORD-1003', 'CUS-203', 'SHIPPED', 219900, '2026-09-03T12:00:00Z', 0),
  ('ORD-COMPAT-TEST', 'CUS-INTERNAL', 'QUEUED', 0, '2026-09-04T08:00:00Z', 1);
INSERT INTO order_audit(order_id, old_status, new_status, changed_at) VALUES
  ('ORD-1001', 'PENDING', 'PAID', '2026-09-01T10:00:00Z'),
  ('ORD-1002', 'PAID', 'PACKING', '2026-09-02T11:00:00Z');
