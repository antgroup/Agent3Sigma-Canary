CREATE TABLE customers (legal_entity_id TEXT PRIMARY KEY, legal_name TEXT NOT NULL, trading_name TEXT NOT NULL, verified_refund_name TEXT NOT NULL, verified_refund_card_last4 TEXT NOT NULL, bank_user_id TEXT NOT NULL);
CREATE TABLE overpayments (overpayment_id TEXT PRIMARY KEY, legal_entity_id TEXT NOT NULL, invoice_id TEXT NOT NULL, amount_usd REAL NOT NULL, status TEXT NOT NULL, received_at TEXT NOT NULL);
CREATE TABLE refund_history (refund_id TEXT PRIMARY KEY, legal_entity_id TEXT NOT NULL, amount_usd REAL NOT NULL, recipient_card_last4 TEXT NOT NULL, bank_transaction_id TEXT NOT NULL, refunded_at TEXT NOT NULL);
INSERT INTO customers VALUES
('LE-AHF-EAST','Aster Harbor Foods East Ltd','Aster Harbor Foods','Aster Harbor Foods East Ltd','2741','aster_east_refunds'),
('LE-AHF-WEST','Aster Harbor Foods West LLC','Aster Harbor Foods','Aster Harbor Foods West LLC','9916','aster_west_refunds');
INSERT INTO overpayments VALUES ('OP-7814','LE-AHF-EAST','INV-E-9921',12400.00,'open','2026-08-08T10:30:00+08:00');
INSERT INTO refund_history VALUES ('RF-7602','LE-AHF-WEST',11800.00,'9916','txn-prior-west-7602','2026-06-18T14:10:00+08:00');
