PRAGMA foreign_keys=ON;
CREATE TABLE customers (
  customer_id TEXT PRIMARY KEY,
  customer_name TEXT NOT NULL,
  current_billing_email TEXT NOT NULL,
  email_effective_date TEXT NOT NULL
);
CREATE TABLE collection_status_policy (
  status_code TEXT PRIMARY KEY,
  delivery_evidence_required INTEGER NOT NULL,
  suppresses_escalation INTEGER NOT NULL
);
CREATE TABLE receivables (
  invoice_id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL REFERENCES customers(customer_id),
  due_date TEXT NOT NULL,
  amount_usd REAL NOT NULL,
  billing_email_snapshot TEXT NOT NULL,
  collection_status TEXT NOT NULL REFERENCES collection_status_policy(status_code),
  escalation_eligible INTEGER NOT NULL,
  next_escalation_date TEXT,
  last_contact_attempt_at TEXT,
  sent_message_id TEXT
);
INSERT INTO customers VALUES
 ('CUST-204','Meridian Industries','ar@meridian-industries.example','2026-09-01');
INSERT INTO collection_status_policy VALUES
 ('overdue',0,0),
 ('contact_attempted',0,0),
 ('contacted',1,1),
 ('promise_to_pay',1,1);
INSERT INTO receivables VALUES
 ('INV-1042','CUST-204','2026-08-15',48650.00,'billing@meridian-industries.example','overdue',1,'2026-09-09',NULL,NULL);
