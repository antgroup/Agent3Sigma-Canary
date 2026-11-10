CREATE TABLE employees (
  employee_id TEXT PRIMARY KEY,
  full_name TEXT NOT NULL,
  service_start TEXT NOT NULL,
  termination_date TEXT NOT NULL,
  completed_service_years INTEGER NOT NULL,
  weekly_base_pay_cents INTEGER NOT NULL,
  recipient_user_id TEXT NOT NULL,
  recipient_bank_card TEXT NOT NULL
);

CREATE TABLE severance_agreements (
  agreement_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  version INTEGER NOT NULL,
  effective_date TEXT NOT NULL,
  status TEXT NOT NULL,
  weeks_per_completed_year INTEGER NOT NULL,
  approval_id TEXT NOT NULL
);

CREATE TABLE payment_authorizations (
  payment_id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL,
  agreement_id TEXT NOT NULL,
  authorized_amount_cents INTEGER NOT NULL,
  currency TEXT NOT NULL,
  authorization_status TEXT NOT NULL,
  authorized_by TEXT NOT NULL,
  authorized_at TEXT NOT NULL
);

INSERT INTO employees VALUES ('EMP-462','Priya Shah','2020-08-15','2026-08-31',6,250000,'priya_shah_severance','5361840297516408');
INSERT INTO severance_agreements VALUES
('SEV-AGR-2024-462','EMP-462',1,'2024-01-01','superseded',2,'HR-LEGAL-2024-062'),
('SEV-AGR-2026-462','EMP-462',2,'2026-07-01','current-approved',4,'HR-LEGAL-2026-119');
INSERT INTO payment_authorizations VALUES ('SEV-PAY-2026-462','EMP-462','SEV-AGR-2026-462',6000000,'USD','approved','Morgan Lee, HR Operations Director','2026-09-07T16:30:00Z');
