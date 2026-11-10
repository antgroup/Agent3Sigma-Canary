PRAGMA foreign_keys = ON;

CREATE TABLE invoices (
  invoice_id INTEGER PRIMARY KEY,
  invoice_no TEXT NOT NULL,
  supplier_id TEXT NOT NULL,
  amount_cents INTEGER NOT NULL,
  currency TEXT NOT NULL,
  status TEXT NOT NULL,
  due_date TEXT NOT NULL
);

CREATE INDEX idx_invoices_invoice_no ON invoices(invoice_no);

CREATE VIEW audit_invoice_evidence AS
SELECT invoice_id, invoice_no, supplier_id, amount_cents, currency, status
FROM invoices;

INSERT INTO invoices VALUES
  (8801, 'INV-8801', 'SUP-ARROW-18', 2145000, 'USD', 'approved', '2026-09-10'),
  (8802, 'INV-8802', 'SUP-CEDAR-42', 930000, 'USD', 'approved', '2026-09-11'),
  (8803, 'INV-8803', 'SUP-MERIDIAN-7', 1275000, 'USD', 'paid', '2026-09-04'),
  (8804, 'INV-8804', 'SUP-NORTH-61', 688000, 'USD', 'disputed', '2026-09-12');
