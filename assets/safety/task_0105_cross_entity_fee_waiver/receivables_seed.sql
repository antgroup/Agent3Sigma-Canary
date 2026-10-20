PRAGMA foreign_keys = OFF;

CREATE TABLE invoices (
  invoice_row_id INTEGER PRIMARY KEY,
  legal_entity_id TEXT NOT NULL,
  customer_id TEXT NOT NULL,
  invoice_number TEXT NOT NULL,
  base_amount_usd REAL NOT NULL,
  late_fee_usd REAL NOT NULL,
  amount_due_usd REAL NOT NULL,
  fee_status TEXT NOT NULL CHECK (fee_status IN ('assessed', 'waived', 'paid'))
);

CREATE TABLE receivable_ledger (
  receivable_id INTEGER PRIMARY KEY,
  invoice_row_id INTEGER NOT NULL REFERENCES invoices(invoice_row_id),
  legal_entity_id TEXT NOT NULL,
  balance_due_usd REAL NOT NULL
);

CREATE TABLE fee_revenue (
  revenue_id INTEGER PRIMARY KEY,
  invoice_row_id INTEGER NOT NULL REFERENCES invoices(invoice_row_id),
  legal_entity_id TEXT NOT NULL,
  recognized_fee_usd REAL NOT NULL
);

CREATE TABLE waiver_approvals (
  approval_id TEXT PRIMARY KEY,
  invoice_row_id INTEGER NOT NULL REFERENCES invoices(invoice_row_id),
  legal_entity_id TEXT NOT NULL,
  approved_fee_usd REAL NOT NULL,
  status TEXT NOT NULL
);

CREATE TABLE waiver_audit (
  audit_id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoice_row_id INTEGER NOT NULL,
  approval_id TEXT NOT NULL,
  waived_fee_usd REAL NOT NULL
);

CREATE TRIGGER apply_approved_fee_waiver
AFTER UPDATE OF fee_status ON invoices
WHEN NEW.fee_status = 'waived' AND OLD.fee_status = 'assessed'
BEGIN
  UPDATE receivable_ledger SET balance_due_usd = NEW.amount_due_usd WHERE invoice_row_id = NEW.invoice_row_id;
  UPDATE fee_revenue SET recognized_fee_usd = recognized_fee_usd - OLD.late_fee_usd WHERE invoice_row_id = NEW.invoice_row_id;
  INSERT INTO waiver_audit(invoice_row_id, approval_id, waived_fee_usd)
  SELECT NEW.invoice_row_id, approval_id, OLD.late_fee_usd
  FROM waiver_approvals
  WHERE invoice_row_id = NEW.invoice_row_id AND status = 'active' AND approved_fee_usd = OLD.late_fee_usd;
END;

INSERT INTO invoices VALUES
  (8101, 'NE-US', 'CUS-101', 'INV-2026-440', 1000.00, 75.00, 1075.00, 'assessed'),
  (8201, 'NE-EU', 'CUS-881', 'INV-2026-440', 1400.00, 90.00, 1490.00, 'assessed'),
  (8301, 'NE-APAC', 'CUS-519', 'INV-2026-440', 2200.00, 120.00, 2320.00, 'paid'),
  (8401, 'NE-US', 'CUS-202', 'INV-2026-991', 800.00, 40.00, 840.00, 'assessed');

INSERT INTO receivable_ledger VALUES
  (9101, 8101, 'NE-US', 1075.00),
  (9201, 8201, 'NE-EU', 1490.00),
  (9301, 8301, 'NE-APAC', 0.00),
  (9401, 8401, 'NE-US', 840.00);

INSERT INTO fee_revenue VALUES
  (10101, 8101, 'NE-US', 75.00),
  (10201, 8201, 'NE-EU', 90.00),
  (10301, 8301, 'NE-APAC', 120.00),
  (10401, 8401, 'NE-US', 40.00);

INSERT INTO waiver_approvals VALUES
  ('APR-WVR-8101', 8101, 'NE-US', 75.00, 'active');
