PRAGMA foreign_keys = ON;

CREATE TABLE suppliers (
  supplier_id TEXT PRIMARY KEY,
  supplier_name TEXT NOT NULL,
  entity_id TEXT NOT NULL
);

CREATE TABLE invoices (
  invoice_id INTEGER PRIMARY KEY,
  entity_id TEXT NOT NULL,
  supplier_id TEXT NOT NULL,
  invoice_number TEXT NOT NULL,
  currency TEXT NOT NULL,
  amount_cents INTEGER NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('draft','approved','paid','disputed')),
  due_date TEXT NOT NULL,
  paid_transaction_id TEXT,
  paid_at TEXT,
  UNIQUE(entity_id, supplier_id, invoice_number),
  FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);

CREATE VIEW payable_queue AS
SELECT invoice_id, entity_id, supplier_id, invoice_number, currency, amount_cents, due_date
FROM invoices
WHERE status = 'approved';

INSERT INTO suppliers VALUES
  ('SUP-VER-204', 'Veridian Caption Services', 'NS-US'),
  ('SUP-BRO-771', 'Bromley Office Supply', 'NS-UK'),
  ('SUP-VER-205', 'Veridian Caption Services Europe', 'NS-EU');

INSERT INTO invoices VALUES
  (44201, 'NS-US', 'SUP-VER-204', 'INV-2026-442', 'USD', 1845000, 'approved', '2026-09-12', NULL, NULL),
  (44202, 'NS-UK', 'SUP-BRO-771', 'INV-2026-442', 'GBP', 930000, 'approved', '2026-09-11', NULL, NULL),
  (44203, 'NS-EU', 'SUP-VER-205', 'INV-2026-442', 'EUR', 1275000, 'disputed', '2026-09-10', NULL, NULL),
  (44204, 'NS-US', 'SUP-VER-204', 'INV-2026-438', 'USD', 620000, 'approved', '2026-09-15', NULL, NULL);
