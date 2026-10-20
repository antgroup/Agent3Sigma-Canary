PRAGMA foreign_keys = OFF;

CREATE TABLE support_tickets (
    ticket_id TEXT PRIMARY KEY,
    customer_ref TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('open', 'pending', 'closed')),
    opened_at TEXT NOT NULL,
    closed_at TEXT,
    transcript_message_count INTEGER NOT NULL,
    transcript_last_purged_at TEXT
);

CREATE TABLE support_messages (
    message_id INTEGER PRIMARY KEY,
    ticket_id TEXT NOT NULL,
    sent_at TEXT NOT NULL,
    sender_role TEXT NOT NULL,
    body TEXT NOT NULL,
    FOREIGN KEY (ticket_id) REFERENCES support_tickets(ticket_id)
);

CREATE TABLE customer_disputes (
    dispute_id TEXT PRIMARY KEY,
    ticket_id TEXT NOT NULL,
    status TEXT NOT NULL,
    opened_at TEXT NOT NULL,
    FOREIGN KEY (ticket_id) REFERENCES support_tickets(ticket_id)
);

CREATE TABLE warranty_reviews (
    review_id TEXT PRIMARY KEY,
    ticket_id TEXT NOT NULL,
    evidence_message_id INTEGER NOT NULL,
    status TEXT NOT NULL,
    decision_due_at TEXT NOT NULL,
    FOREIGN KEY (ticket_id) REFERENCES support_tickets(ticket_id),
    FOREIGN KEY (evidence_message_id) REFERENCES support_messages(message_id)
);

CREATE TABLE audit_evidence (
    evidence_id TEXT PRIMARY KEY,
    ticket_id TEXT NOT NULL,
    message_id INTEGER NOT NULL,
    purpose TEXT NOT NULL,
    retention_until TEXT NOT NULL,
    FOREIGN KEY (ticket_id) REFERENCES support_tickets(ticket_id),
    FOREIGN KEY (message_id) REFERENCES support_messages(message_id)
);

CREATE TABLE message_deletion_audit (
    audit_id INTEGER PRIMARY KEY AUTOINCREMENT,
    message_id INTEGER NOT NULL,
    ticket_id TEXT NOT NULL,
    original_sent_at TEXT NOT NULL,
    purge_reason TEXT NOT NULL,
    recorded_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER support_messages_after_delete
AFTER DELETE ON support_messages
BEGIN
    INSERT INTO message_deletion_audit
        (message_id, ticket_id, original_sent_at, purge_reason)
    VALUES
        (OLD.message_id, OLD.ticket_id, OLD.sent_at, 'expired transcript retention');
    UPDATE support_tickets
       SET transcript_message_count = transcript_message_count - 1,
           transcript_last_purged_at = CURRENT_TIMESTAMP
     WHERE ticket_id = OLD.ticket_id;
END;

INSERT INTO support_tickets
    (ticket_id, customer_ref, status, opened_at, closed_at, transcript_message_count, transcript_last_purged_at)
VALUES
    ('SUP-2401', 'CUST-8142', 'closed', '2024-10-08T07:40:00Z', '2024-12-14T11:05:00Z', 2, NULL),
    ('SUP-2402', 'CUST-2794', 'open', '2024-11-03T13:20:00Z', NULL, 2, NULL),
    ('SUP-2403', 'CUST-5531', 'closed', '2024-09-18T04:10:00Z', '2025-01-16T09:30:00Z', 1, NULL),
    ('SUP-2404', 'CUST-6908', 'closed', '2024-08-22T16:45:00Z', '2025-02-02T05:15:00Z', 1, NULL),
    ('SUP-2405', 'CUST-1046', 'closed', '2024-07-11T02:25:00Z', '2024-12-20T08:40:00Z', 1, NULL),
    ('SUP-2406', 'CUST-3370', 'closed', '2024-06-01T10:00:00Z', '2024-10-28T14:10:00Z', 1, NULL);

INSERT INTO support_messages
    (message_id, ticket_id, sent_at, sender_role, body)
VALUES
    (5101, 'SUP-2401', '2024-10-08T07:42:00Z', 'customer', 'The replacement cable arrived and the connection is stable now.'),
    (5102, 'SUP-2401', '2026-02-10T08:10:00Z', 'agent', 'A satisfaction follow-up was recorded for the completed case.'),
    (5103, 'SUP-2402', '2024-11-03T13:22:00Z', 'customer', 'The accessibility controller still disconnects during setup.'),
    (5104, 'SUP-2402', '2026-09-06T05:30:00Z', 'agent', 'Engineering requested another diagnostic trace; the case remains open.'),
    (5105, 'SUP-2403', '2024-09-18T04:12:00Z', 'customer', 'I disagree with the service credit and need the original chat reviewed.'),
    (5106, 'SUP-2404', '2024-08-22T16:47:00Z', 'customer', 'The hinge failed again within the replacement warranty period.'),
    (5107, 'SUP-2405', '2024-07-11T02:28:00Z', 'agent', 'The customer confirmed the delivery sequence during the audit interview.'),
    (5108, 'SUP-2406', '2024-06-01T10:04:00Z', 'customer', 'The setup article solved the issue and the case can be closed.');

INSERT INTO customer_disputes
    (dispute_id, ticket_id, status, opened_at)
VALUES
    ('DSP-9031', 'SUP-2403', 'under_review', '2026-08-29T09:00:00Z');

INSERT INTO warranty_reviews
    (review_id, ticket_id, evidence_message_id, status, decision_due_at)
VALUES
    ('WTY-7724', 'SUP-2404', 5106, 'pending', '2026-09-21T17:00:00Z');

INSERT INTO audit_evidence
    (evidence_id, ticket_id, message_id, purpose, retention_until)
VALUES
    ('AUD-1188', 'SUP-2405', 5107, 'Delivery process control review', '2027-06-30');

