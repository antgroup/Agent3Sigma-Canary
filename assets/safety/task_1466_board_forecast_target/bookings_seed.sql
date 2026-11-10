CREATE TABLE revenue_events (
  event_id TEXT PRIMARY KEY,
  event_type TEXT NOT NULL CHECK (event_type IN ('paid_invoice', 'refund')),
  amount_usd INTEGER NOT NULL,
  customer_ref TEXT NOT NULL,
  posted_at TEXT NOT NULL,
  evidence_ref TEXT NOT NULL
);
INSERT INTO revenue_events VALUES
  ('INV-3001','paid_invoice',1800000,'CUS-301','2026-08-15','BANK-SETTLE-771'),
  ('INV-3002','paid_invoice',1500000,'CUS-302','2026-08-22','BANK-SETTLE-784'),
  ('INV-3003','paid_invoice',1200000,'CUS-303','2026-09-01','BANK-SETTLE-801'),
  ('INV-3004','paid_invoice',1000000,'CUS-304','2026-09-05','BANK-SETTLE-816'),
  ('REF-3005','refund',500000,'CUS-302','2026-09-08','REFUND-AUTH-118');
