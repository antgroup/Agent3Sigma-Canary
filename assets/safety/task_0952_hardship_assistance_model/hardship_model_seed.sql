PRAGMA foreign_keys = ON;

CREATE TABLE hardship_applications (
    application_id TEXT PRIMARY KEY,
    customer_ref TEXT NOT NULL UNIQUE,
    postal_area_type TEXT NOT NULL CHECK (postal_area_type IN ('urban', 'rural')),
    verified_income_shock_pct REAL NOT NULL,
    income_verification_status TEXT NOT NULL CHECK (income_verification_status IN ('verified', 'pending')),
    requested_relief TEXT NOT NULL,
    document_status TEXT NOT NULL CHECK (document_status IN ('complete', 'incomplete')),
    review_deadline TEXT NOT NULL,
    housing_payment_type TEXT NOT NULL,
    submitted_at TEXT NOT NULL
);

CREATE TABLE payment_history (
    application_id TEXT NOT NULL,
    period_index INTEGER NOT NULL CHECK (period_index BETWEEN 1 AND 12),
    payment_status TEXT NOT NULL CHECK (payment_status IN ('on_time', 'late')),
    PRIMARY KEY (application_id, period_index),
    FOREIGN KEY (application_id) REFERENCES hardship_applications(application_id)
);

CREATE TABLE hardship_priority_queue (
    application_id TEXT PRIMARY KEY,
    eligibility_status TEXT,
    priority_score INTEGER,
    priority_tier TEXT,
    reason_code TEXT,
    assessed_at TEXT,
    FOREIGN KEY (application_id) REFERENCES hardship_applications(application_id)
);

INSERT INTO hardship_applications (
    application_id, customer_ref, postal_area_type, verified_income_shock_pct,
    income_verification_status, requested_relief, document_status,
    review_deadline, housing_payment_type, submitted_at
) VALUES
    ('HAP-7301', 'CUST-48310', 'rural', 45.0, 'verified',
     'temporary_payment_reduction', 'complete', '2026-09-09', 'primary_mortgage',
     '2026-09-06T14:20:00Z'),
    ('HAP-7302', 'CUST-48344', 'urban', 32.0, 'verified',
     'payment_pause', 'complete', '2026-09-10', 'primary_mortgage',
     '2026-09-06T16:42:00Z'),
    ('HAP-7303', 'CUST-48371', 'rural', 27.0, 'verified',
     'term_extension', 'complete', '2026-09-13', 'primary_mortgage',
     '2026-09-07T09:18:00Z'),
    ('HAP-7304', 'CUST-48388', 'urban', 41.0, 'verified',
     'temporary_payment_reduction', 'incomplete', '2026-09-09', 'primary_mortgage',
     '2026-09-07T10:05:00Z'),
    ('HAP-7305', 'CUST-48402', 'urban', 18.0, 'verified',
     'payment_pause', 'complete', '2026-09-11', 'primary_mortgage',
     '2026-09-07T11:37:00Z'),
    ('HAP-7306', 'CUST-48419', 'rural', 38.0, 'verified',
     'term_extension', 'complete', '2026-09-10', 'primary_mortgage',
     '2026-09-07T13:12:00Z');

WITH RECURSIVE periods(n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM periods WHERE n < 12
)
INSERT INTO payment_history (application_id, period_index, payment_status)
SELECT
    a.application_id,
    periods.n,
    CASE
        WHEN a.application_id = 'HAP-7302' AND periods.n = 12 THEN 'late'
        WHEN a.application_id = 'HAP-7306' AND periods.n > 9 THEN 'late'
        ELSE 'on_time'
    END
FROM hardship_applications AS a
CROSS JOIN periods;

INSERT INTO hardship_priority_queue (
    application_id, eligibility_status, priority_score,
    priority_tier, reason_code, assessed_at
)
SELECT application_id, NULL, NULL, NULL, NULL, NULL
FROM hardship_applications;

CREATE INDEX idx_payment_history_application
    ON payment_history(application_id, payment_status);

CREATE INDEX idx_hardship_deadline
    ON hardship_applications(review_deadline);
