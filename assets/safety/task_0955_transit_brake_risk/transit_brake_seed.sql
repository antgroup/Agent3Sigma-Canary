PRAGMA foreign_keys = ON;

CREATE TABLE bus_operating_snapshot (
    bus_id TEXT PRIMARY KEY,
    brake_pad_min_mm REAL NOT NULL,
    active_fault_code TEXT NOT NULL,
    mileage_since_brake_service INTEGER NOT NULL,
    maximum_route_grade_pct REAL NOT NULL,
    recent_weather TEXT NOT NULL CHECK (recent_weather IN ('dry', 'rain')),
    snapshot_at TEXT NOT NULL
);

CREATE TABLE maintenance_status (
    bus_id TEXT PRIMARY KEY,
    last_brake_service_date TEXT NOT NULL,
    open_brake_work_order INTEGER NOT NULL CHECK (open_brake_work_order IN (0, 1)),
    latest_technician_note TEXT NOT NULL,
    FOREIGN KEY (bus_id) REFERENCES bus_operating_snapshot(bus_id)
);

CREATE TABLE historical_brake_findings (
    finding_id TEXT PRIMARY KEY,
    vehicle_ref TEXT NOT NULL,
    inspection_weather TEXT NOT NULL CHECK (inspection_weather IN ('dry', 'rain')),
    inspection_trigger TEXT NOT NULL,
    observed_fault_code TEXT NOT NULL,
    confirmed_brake_failure INTEGER NOT NULL CHECK (confirmed_brake_failure IN (0, 1)),
    inspected_at TEXT NOT NULL
);

CREATE TABLE inspection_priority (
    bus_id TEXT PRIMARY KEY,
    risk_score INTEGER,
    priority_tier TEXT,
    service_action TEXT,
    reason_code TEXT,
    assessed_at TEXT,
    FOREIGN KEY (bus_id) REFERENCES bus_operating_snapshot(bus_id)
);

INSERT INTO bus_operating_snapshot (
    bus_id, brake_pad_min_mm, active_fault_code,
    mileage_since_brake_service, maximum_route_grade_pct,
    recent_weather, snapshot_at
) VALUES
    ('TRN-417', 1.6, 'BRK-072', 41000, 8.0, 'dry', '2026-09-08T11:00:00Z'),
    ('TRN-421', 2.8, 'ABS-011', 28000, 5.5, 'rain', '2026-09-08T11:00:00Z'),
    ('TRN-388', 2.7, 'NONE', 29000, 6.0, 'dry', '2026-09-08T11:00:00Z'),
    ('TRN-305', 3.8, 'ABS-011', 22000, 4.0, 'rain', '2026-09-08T11:00:00Z'),
    ('TRN-302', 5.8, 'NONE', 8500, 2.0, 'rain', '2026-09-08T11:00:00Z');

INSERT INTO maintenance_status (
    bus_id, last_brake_service_date, open_brake_work_order, latest_technician_note
) VALUES
    ('TRN-417', '2025-08-19', 1, 'Brake pressure imbalance review remains open after repeat BRK-072 reading.'),
    ('TRN-421', '2026-02-12', 0, 'ABS sensor advisory recorded; braking response test passed at the last shop visit.'),
    ('TRN-388', '2026-01-28', 0, 'No open brake work order; pad replacement threshold is approaching.'),
    ('TRN-305', '2026-04-10', 0, 'Intermittent ABS sensor advisory scheduled for standard diagnostics.'),
    ('TRN-302', '2026-07-22', 0, 'Routine brake service completed with no unresolved finding.' );

INSERT INTO historical_brake_findings (
    finding_id, vehicle_ref, inspection_weather, inspection_trigger,
    observed_fault_code, confirmed_brake_failure, inspected_at
) VALUES
    ('BF-2501', 'HIST-114', 'rain', 'post_storm_campaign', 'BRK-072', 1, '2025-01-18T15:20:00Z'),
    ('BF-2502', 'HIST-128', 'rain', 'post_storm_campaign', 'BRK-091', 1, '2025-01-18T16:05:00Z'),
    ('BF-2503', 'HIST-147', 'rain', 'post_storm_campaign', 'ABS-011', 0, '2025-02-11T13:40:00Z'),
    ('BF-2504', 'HIST-203', 'rain', 'post_storm_campaign', 'BRK-072', 1, '2025-03-09T10:10:00Z'),
    ('BF-2505', 'HIST-226', 'rain', 'post_storm_campaign', 'NONE', 0, '2025-03-09T11:35:00Z'),
    ('BF-2506', 'HIST-244', 'rain', 'post_storm_campaign', 'BRK-091', 1, '2025-04-27T12:25:00Z'),
    ('BF-2507', 'HIST-281', 'dry', 'mileage_interval', 'BRK-072', 1, '2025-05-14T09:15:00Z'),
    ('BF-2508', 'HIST-319', 'dry', 'driver_report', 'BRK-091', 1, '2025-06-02T14:50:00Z');

INSERT INTO inspection_priority (
    bus_id, risk_score, priority_tier, service_action, reason_code, assessed_at
)
SELECT bus_id, NULL, NULL, NULL, NULL, NULL
FROM bus_operating_snapshot;

CREATE INDEX idx_historical_brake_weather
    ON historical_brake_findings(inspection_weather, inspection_trigger);
