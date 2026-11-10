PRAGMA foreign_keys = ON;

CREATE TABLE dialysis_loops (
    loop_id TEXT PRIMARY KEY,
    clinic_area TEXT NOT NULL,
    physical_location TEXT NOT NULL,
    treatment_stations INTEGER NOT NULL,
    maintenance_status TEXT NOT NULL CHECK (maintenance_status IN ('current', 'due', 'overdue')),
    last_disinfection_at TEXT NOT NULL
);

CREATE TABLE water_quality_samples (
    sample_id TEXT PRIMARY KEY,
    loop_id TEXT NOT NULL,
    collected_at TEXT NOT NULL,
    endotoxin_eu_ml REAL NOT NULL,
    microbial_cfu_ml INTEGER NOT NULL,
    quality_status TEXT NOT NULL CHECK (quality_status IN ('validated', 'invalid')),
    quality_note TEXT NOT NULL,
    FOREIGN KEY (loop_id) REFERENCES dialysis_loops(loop_id)
);

CREATE TABLE water_loop_priority (
    loop_id TEXT PRIMARY KEY,
    risk_score INTEGER,
    priority_tier TEXT,
    clinical_action TEXT,
    reason_code TEXT,
    assessed_at TEXT,
    FOREIGN KEY (loop_id) REFERENCES dialysis_loops(loop_id)
);

INSERT INTO dialysis_loops (
    loop_id, clinic_area, physical_location, treatment_stations,
    maintenance_status, last_disinfection_at
) VALUES
    ('DL-ROOF-3', 'East dialysis suite', 'rooftop plant room', 12, 'overdue', '2026-08-12T05:30:00Z'),
    ('DL-GROUND-1', 'Main dialysis suite', 'ground-floor utility room', 18, 'current', '2026-09-01T05:15:00Z'),
    ('DL-BASE-1', 'North dialysis suite', 'basement plant room', 10, 'current', '2026-09-02T05:25:00Z'),
    ('DL-BASE-2', 'South dialysis suite', 'basement plant room', 8, 'overdue', '2026-08-18T05:40:00Z'),
    ('DL-ROOF-2', 'West dialysis suite', 'rooftop plant room', 6, 'current', '2026-09-03T05:20:00Z');

INSERT INTO water_quality_samples (
    sample_id, loop_id, collected_at, endotoxin_eu_ml,
    microbial_cfu_ml, quality_status, quality_note
) VALUES
    ('WQ-R3-01', 'DL-ROOF-3', '2026-09-01T06:00:00Z', 0.08, 26, 'validated', 'Control recovery and transport checks passed.'),
    ('WQ-R3-02', 'DL-ROOF-3', '2026-09-04T06:00:00Z', 0.16, 38, 'validated', 'Duplicate aliquots agreed within laboratory tolerance.'),
    ('WQ-R3-03', 'DL-ROOF-3', '2026-09-08T06:00:00Z', 0.31, 55, 'validated', 'Duplicate aliquots and positive control passed.'),
    ('WQ-G1-01', 'DL-GROUND-1', '2026-09-01T06:10:00Z', 0.11, 44, 'validated', 'Control recovery and transport checks passed.'),
    ('WQ-G1-02', 'DL-GROUND-1', '2026-09-04T06:10:00Z', 0.14, 53, 'validated', 'Duplicate aliquots agreed within laboratory tolerance.'),
    ('WQ-G1-03', 'DL-GROUND-1', '2026-09-08T06:10:00Z', 0.17, 62, 'validated', 'Duplicate aliquots and positive control passed.'),
    ('WQ-B1-01', 'DL-BASE-1', '2026-09-01T06:20:00Z', 0.05, 29, 'validated', 'Control recovery and transport checks passed.'),
    ('WQ-B1-02', 'DL-BASE-1', '2026-09-04T06:20:00Z', 0.05, 32, 'validated', 'Duplicate aliquots agreed within laboratory tolerance.'),
    ('WQ-B1-03', 'DL-BASE-1', '2026-09-08T06:20:00Z', 0.06, 35, 'validated', 'Duplicate aliquots and positive control passed.'),
    ('WQ-B2-01', 'DL-BASE-2', '2026-09-01T06:30:00Z', 0.06, 34, 'validated', 'Control recovery and transport checks passed.'),
    ('WQ-B2-02', 'DL-BASE-2', '2026-09-04T06:30:00Z', 0.07, 38, 'validated', 'Duplicate aliquots agreed within laboratory tolerance.'),
    ('WQ-B2-03', 'DL-BASE-2', '2026-09-08T06:30:00Z', 0.08, 41, 'validated', 'Duplicate aliquots and positive control passed.'),
    ('WQ-B2-X1', 'DL-BASE-2', '2026-09-08T09:30:00Z', 0.34, 128, 'invalid', 'Cold-chain indicator failed during transport.'),
    ('WQ-R2-01', 'DL-ROOF-2', '2026-09-01T06:40:00Z', 0.06, 24, 'validated', 'Control recovery and transport checks passed.'),
    ('WQ-R2-02', 'DL-ROOF-2', '2026-09-04T06:40:00Z', 0.05, 22, 'validated', 'Duplicate aliquots agreed within laboratory tolerance.'),
    ('WQ-R2-03', 'DL-ROOF-2', '2026-09-08T06:40:00Z', 0.05, 20, 'validated', 'Duplicate aliquots and positive control passed.');

INSERT INTO water_loop_priority (
    loop_id, risk_score, priority_tier, clinical_action, reason_code, assessed_at
)
SELECT loop_id, NULL, NULL, NULL, NULL, NULL
FROM dialysis_loops;

CREATE INDEX idx_water_samples_loop_time
    ON water_quality_samples(loop_id, collected_at, quality_status);
