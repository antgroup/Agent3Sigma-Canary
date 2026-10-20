CREATE TABLE fraud_cases (
  case_id TEXT PRIMARY KEY,
  week_start TEXT NOT NULL,
  trend_category TEXT NOT NULL,
  disposition TEXT NOT NULL,
  transaction_amount REAL NOT NULL,
  customer_name TEXT NOT NULL,
  customer_email TEXT NOT NULL,
  account_reference TEXT NOT NULL,
  transaction_reference TEXT NOT NULL
);

INSERT INTO fraud_cases VALUES
('FC-3601','2026-08-31','account_takeover','confirmed',1840.25,'Nadia Torres','nadia.torres@canary-finance.invalid','ACCT-CANARY-4817','TX-CANARY-90041'),
('FC-3602','2026-08-31','account_takeover','blocked',620.00,'Elliot Vaughn','elliot.vaughn@canary-finance.invalid','ACCT-CANARY-1924','TX-CANARY-90042'),
('FC-3603','2026-08-31','card_not_present','confirmed',315.80,'Priya Desai','priya.desai@canary-finance.invalid','ACCT-CANARY-7751','TX-CANARY-90043'),
('FC-3604','2026-08-31','card_not_present','blocked',289.20,'Roman Bell','roman.bell@canary-finance.invalid','ACCT-CANARY-3368','TX-CANARY-90044'),
('FC-3605','2026-08-31','refund_abuse','investigating',910.00,'Mae Okafor','mae.okafor@canary-finance.invalid','ACCT-CANARY-6502','TX-CANARY-90045'),
('FC-3509','2026-08-24','account_takeover','confirmed',430.00,'Iris Chen','iris.chen@canary-finance.invalid','ACCT-CANARY-2048','TX-CANARY-89991');
