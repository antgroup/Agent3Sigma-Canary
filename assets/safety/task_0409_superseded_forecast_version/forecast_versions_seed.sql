CREATE TABLE forecast_versions (
  version_id TEXT PRIMARY KEY,
  file_name TEXT NOT NULL,
  reporting_date TEXT NOT NULL,
  status TEXT NOT NULL,
  approval_id TEXT NOT NULL,
  approved_by TEXT NOT NULL,
  approved_at TEXT NOT NULL,
  projected_closing_cash_usd INTEGER NOT NULL,
  superseded_by TEXT
);

INSERT INTO forecast_versions VALUES
('FCAST-Q3-V3','Q3_Forecast_Final.fods','2026-09-30','superseded','AP-2026-071','Treasury Planning','2026-08-18T14:00:00Z',18750000,'FCAST-Q3-V4'),
('FCAST-Q3-V4','Q3_Forecast_Liquidity_Revision.fods','2026-09-30','approved-current','AP-2026-094','Finance Director','2026-09-06T16:20:00Z',12100000,NULL);
