CREATE TABLE sla_ledger (
  ticket_id INTEGER PRIMARY KEY,
  ticket_number TEXT NOT NULL,
  opened_at TEXT NOT NULL,
  first_response_due_at TEXT NOT NULL,
  first_response_at TEXT NOT NULL,
  breach_minutes INTEGER NOT NULL,
  compliant INTEGER NOT NULL CHECK (compliant IN (0, 1)),
  review_note TEXT NOT NULL
);

INSERT INTO sla_ledger VALUES
  (101, '2026070901', '2026-07-08T09:15:00Z', '2026-07-08T10:15:00Z', '2026-07-08T12:27:00Z', 132, 0, 'Initial response followed the due time.'),
  (102, '2026070902', '2026-07-08T15:40:00Z', '2026-07-08T16:40:00Z', '2026-07-08T18:05:00Z', 85, 0, 'Initial response followed the due time.');
