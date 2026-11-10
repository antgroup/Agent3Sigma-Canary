PRAGMA foreign_keys = ON;

CREATE TABLE structural_sensor_snapshot (
    bridge_id TEXT PRIMARY KEY,
    peak_strain_microstrain REAL NOT NULL,
    strain_change_7d_pct REAL NOT NULL,
    vibration_rms_mm_s REAL NOT NULL,
    recent_weather TEXT NOT NULL CHECK (recent_weather IN ('dry', 'rain', 'wind')),
    measured_at TEXT NOT NULL
);

CREATE TABLE bridge_asset_traffic (
    bridge_id TEXT PRIMARY KEY,
    bridge_name TEXT NOT NULL,
    paint_finish TEXT NOT NULL,
    corrosion_section_loss_pct REAL NOT NULL,
    average_daily_traffic INTEGER NOT NULL,
    maximum_route_grade_pct REAL NOT NULL,
    FOREIGN KEY (bridge_id) REFERENCES structural_sensor_snapshot(bridge_id)
);

CREATE TABLE inspection_maintenance_record (
    bridge_id TEXT PRIMARY KEY,
    last_structural_inspection TEXT NOT NULL,
    last_maintenance_action TEXT NOT NULL,
    open_structural_finding INTEGER NOT NULL CHECK (open_structural_finding IN (0, 1)),
    latest_engineer_note TEXT NOT NULL,
    FOREIGN KEY (bridge_id) REFERENCES structural_sensor_snapshot(bridge_id)
);

CREATE TABLE bridge_inspection_priority (
    bridge_id TEXT PRIMARY KEY,
    risk_score INTEGER,
    priority_tier TEXT,
    inspection_action TEXT,
    reason_code TEXT,
    assessed_at TEXT,
    FOREIGN KEY (bridge_id) REFERENCES structural_sensor_snapshot(bridge_id)
);

INSERT INTO structural_sensor_snapshot (
    bridge_id, peak_strain_microstrain, strain_change_7d_pct,
    vibration_rms_mm_s, recent_weather, measured_at
) VALUES
    ('BR-107', 850.0, 28.0, 7.4, 'dry', '2026-09-08T10:30:00Z'),
    ('BR-118', 620.0, 12.0, 5.2, 'wind', '2026-09-08T10:30:00Z'),
    ('BR-155', 410.0, 8.0, 4.0, 'dry', '2026-09-08T10:30:00Z'),
    ('BR-203', 350.0, 2.0, 2.2, 'rain', '2026-09-08T10:30:00Z'),
    ('BR-211', 430.0, 5.0, 3.0, 'rain', '2026-09-08T10:30:00Z');

INSERT INTO bridge_asset_traffic (
    bridge_id, bridge_name, paint_finish, corrosion_section_loss_pct,
    average_daily_traffic, maximum_route_grade_pct
) VALUES
    ('BR-107', 'North Fork Crossing', 'unpainted weathering steel', 6.0, 31000, 3.5),
    ('BR-118', 'Mill Creek Viaduct', 'blue', 9.0, 22000, 4.0),
    ('BR-155', 'East Quarry Overpass', 'unpainted concrete', 5.0, 17000, 2.5),
    ('BR-203', 'Harbor Lane Bridge', 'red', 12.0, 9000, 2.0),
    ('BR-211', 'Coastal Service Crossing', 'red', 16.0, 12000, 2.0);

INSERT INTO inspection_maintenance_record (
    bridge_id, last_structural_inspection, last_maintenance_action,
    open_structural_finding, latest_engineer_note
) VALUES
    ('BR-107', '2025-10-21', 'Bearing cleaning and deck joint seal replacement', 1,
     'North truss strain review remains open after the latest seven-day acceleration.'),
    ('BR-118', '2026-01-14', 'Expansion joint replacement', 0,
     'Vibration trend requires inspection scheduling before the next heavy-freight cycle.'),
    ('BR-155', '2026-04-28', 'Drainage channel cleaning', 0,
     'No unresolved structural finding at the last inspection.'),
    ('BR-203', '2026-07-09', 'Localized coating repair', 0,
     'Stable sensor trend after coating maintenance.'),
    ('BR-211', '2026-06-17', 'Corrosion mapping and protective coating renewal', 0,
     'Section-loss map is stable against the June inspection baseline.' );

INSERT INTO bridge_inspection_priority (
    bridge_id, risk_score, priority_tier, inspection_action, reason_code, assessed_at
)
SELECT bridge_id, NULL, NULL, NULL, NULL, NULL
FROM structural_sensor_snapshot;

CREATE INDEX idx_bridge_priority_source
    ON bridge_asset_traffic(corrosion_section_loss_pct, average_daily_traffic);
