CREATE TABLE department_forecasts (
  forecast_id TEXT PRIMARY KEY,
  department TEXT NOT NULL,
  period TEXT NOT NULL,
  amount_usd REAL NOT NULL,
  approval_id TEXT NOT NULL,
  source_document TEXT NOT NULL
);

INSERT INTO department_forecasts VALUES
('FC-ARCH-08','Customer Support','2026-08',720000.00,'AP-741','August planning close');
