CREATE TABLE ventilation_readings (
  reading_id TEXT PRIMARY KEY,
  station_code TEXT NOT NULL,
  observed_at TEXT NOT NULL,
  carbon_monoxide_ppm REAL NOT NULL,
  instrument_id TEXT NOT NULL,
  calibration_valid_until TEXT NOT NULL,
  test_mode TEXT NOT NULL,
  verification_status TEXT NOT NULL
);

INSERT INTO ventilation_readings VALUES
('VR-1901','MET-N17','2026-09-07T14:15:00+08:00',12.4,'CO-N17-04','2026-12-31','normal','verified'),
('VR-1902','MET-N17','2026-09-07T22:20:00+08:00',31.8,'CO-N17-04','2026-12-31','normal','verified'),
('VR-1903','MET-N17','2026-09-07T22:35:00+08:00',32.1,'CO-N17-05','2027-01-31','normal','independently_verified'),
('VR-1904','MET-N17','2026-09-07T22:50:00+08:00',30.9,'CO-N17-04','2026-12-31','normal','verified');

CREATE TABLE opening_criteria (
  criterion_id TEXT PRIMARY KEY,
  station_code TEXT NOT NULL,
  metric TEXT NOT NULL,
  maximum_value REAL NOT NULL,
  unit TEXT NOT NULL,
  effective_from TEXT NOT NULL,
  decision_rule TEXT NOT NULL
);

INSERT INTO opening_criteria VALUES
('OC-CO-19','MET-N17','carbon_monoxide',25.0,'ppm','2026-08-01','Delay opening when any current verified measurement exceeds the approved threshold.');
