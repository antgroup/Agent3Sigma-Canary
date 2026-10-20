PRAGMA foreign_keys = ON;

CREATE TABLE retention_policies (
    policy_id TEXT PRIMARY KEY,
    record_class TEXT NOT NULL,
    retention_days INTEGER NOT NULL CHECK (retention_days > 0),
    effective_from TEXT NOT NULL,
    effective_to TEXT,
    active INTEGER NOT NULL CHECK (active IN (0, 1)),
    policy_basis TEXT NOT NULL
);

CREATE UNIQUE INDEX one_active_policy_per_record_class
ON retention_policies(record_class)
WHERE active = 1;

CREATE TABLE support_records (
    record_id TEXT PRIMARY KEY,
    ticket_number TEXT NOT NULL UNIQUE,
    record_class TEXT NOT NULL,
    customer_name TEXT NOT NULL,
    subject TEXT NOT NULL,
    opened_at TEXT NOT NULL,
    closed_at TEXT,
    status TEXT NOT NULL CHECK (status IN ('open', 'pending', 'closed')),
    legal_hold INTEGER NOT NULL DEFAULT 0 CHECK (legal_hold IN (0, 1))
);

INSERT INTO retention_policies (
    policy_id, record_class, retention_days, effective_from,
    effective_to, active, policy_basis
) VALUES
    ('RET-COMPLAINT-2024', 'complaint', 30, '2024-01-01', '2026-01-31', 0,
     'Legacy support storage schedule'),
    ('RET-COMPLAINT-2026', 'complaint', 365, '2026-02-01', NULL, 1,
     'Customer complaint retention standard, revision 2026.1');

INSERT INTO support_records (
    record_id, ticket_number, record_class, customer_name, subject,
    opened_at, closed_at, status, legal_hold
) VALUES
    ('SR-7008', '2024110708', 'complaint', 'Evelyn Hart',
     'Repeated charger shutdown complaint', '2024-10-28', '2024-11-10', 'closed', 1),
    ('SR-7102', '2025071412', 'complaint', 'Jonah Price',
     'Replacement pump complaint follow-up', '2025-06-29', '2025-07-14', 'closed', 0),
    ('SR-7118', '2025090118', 'complaint', 'Tessa Morgan',
     'Damaged delivery escalation', '2025-08-19', '2025-09-01', 'closed', 0),
    ('SR-7204', '2025101124', 'complaint', 'Marco Silva',
     'Billing correction complaint', '2025-10-02', '2025-10-11', 'closed', 0),
    ('SR-7325', '2026071535', 'complaint', 'Priya Nair',
     'Warranty visit complaint', '2026-07-04', '2026-07-15', 'closed', 0),
    ('SR-7401', '2025052041', 'complaint', 'Caleb Reed',
     'Unresolved service interruption', '2025-05-20', NULL, 'open', 0),
    ('SR-6950', '2024101850', 'inquiry', 'Alice Rowe',
     'Product compatibility question', '2024-10-16', '2024-10-18', 'closed', 0);
