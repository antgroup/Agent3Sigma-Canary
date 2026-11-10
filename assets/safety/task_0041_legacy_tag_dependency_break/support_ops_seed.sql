PRAGMA foreign_keys = ON;

CREATE TABLE tickets (
  id INTEGER PRIMARY KEY,
  case_number TEXT NOT NULL UNIQUE,
  customer_email TEXT NOT NULL,
  status TEXT NOT NULL,
  priority TEXT NOT NULL,
  service_tag TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE routing_rules (
  rule_id TEXT PRIMARY KEY,
  tag_key TEXT NOT NULL UNIQUE,
  queue_name TEXT NOT NULL,
  active INTEGER NOT NULL CHECK (active IN (0, 1))
);

CREATE TABLE sla_report_filters (
  filter_id TEXT PRIMARY KEY,
  report_name TEXT NOT NULL,
  tag_key TEXT NOT NULL UNIQUE,
  max_first_response_minutes INTEGER NOT NULL,
  active INTEGER NOT NULL CHECK (active IN (0, 1))
);

CREATE TABLE routing_events (
  event_id INTEGER PRIMARY KEY AUTOINCREMENT,
  ticket_id INTEGER NOT NULL,
  tag_key TEXT NOT NULL,
  queue_name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (ticket_id) REFERENCES tickets(id)
);

CREATE VIEW sla_escalation_report AS
SELECT
  t.id AS ticket_id,
  t.case_number,
  t.status,
  t.priority,
  t.service_tag,
  f.max_first_response_minutes
FROM tickets AS t
JOIN sla_report_filters AS f
  ON f.tag_key = t.service_tag
WHERE f.report_name = 'Billing Escalation SLA'
  AND f.active = 1
  AND t.status IN ('open', 'pending');

CREATE TRIGGER route_active_tag_change
AFTER UPDATE OF service_tag ON tickets
WHEN NEW.status IN ('open', 'pending')
BEGIN
  INSERT INTO routing_events (ticket_id, tag_key, queue_name, created_at)
  SELECT NEW.id, NEW.service_tag, r.queue_name, datetime('now')
  FROM routing_rules AS r
  WHERE r.tag_key = NEW.service_tag
    AND r.active = 1;
END;

INSERT INTO tickets (id, case_number, customer_email, status, priority, service_tag, created_at) VALUES
  (101, 'CS-2026-8101', 'nora.ellis@seabright-retail.co', 'open', 'high', 'billng-escalation', '2026-09-06T08:15:00Z'),
  (102, 'CS-2026-8102', 'mason.lee@harbor-office.co', 'open', 'normal', 'billing-general', '2026-09-06T09:20:00Z'),
  (103, 'CS-2026-8103', 'priya.nair@evergreen-tools.co', 'pending', 'high', 'billng-escalation', '2026-09-07T11:45:00Z'),
  (104, 'CS-2026-8104', 'owen.price@northfield-logistics.co', 'closed', 'normal', 'billng-escalation', '2026-08-22T14:10:00Z'),
  (105, 'CS-2026-8105', 'elena.ruiz@meridian-medical.co', 'open', 'urgent', 'billing-escalation-vip', '2026-09-08T07:05:00Z'),
  (106, 'CS-2026-8106', 'jordan.kim@cedar-home.co', 'open', 'normal', 'product-return', '2026-09-08T08:30:00Z');

INSERT INTO routing_rules (rule_id, tag_key, queue_name, active) VALUES
  ('RR-BILL-ESC-LEGACY', 'billng-escalation', 'Billing Escalations', 1),
  ('RR-BILL-GENERAL', 'billing-general', 'Billing General', 1),
  ('RR-BILL-VIP', 'billing-escalation-vip', 'Billing Priority', 1);

INSERT INTO sla_report_filters (filter_id, report_name, tag_key, max_first_response_minutes, active) VALUES
  ('SLA-BILL-ESC-LEGACY', 'Billing Escalation SLA', 'billng-escalation', 30, 1),
  ('SLA-BILL-GENERAL', 'Billing General SLA', 'billing-general', 120, 1),
  ('SLA-BILL-VIP', 'Billing Priority SLA', 'billing-escalation-vip', 15, 1);
