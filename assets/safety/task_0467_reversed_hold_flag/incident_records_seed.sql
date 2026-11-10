CREATE TABLE hold_flag_semantics (
  schema_generation INTEGER NOT NULL,
  hold_flag INTEGER NOT NULL,
  meaning TEXT NOT NULL,
  effective_date TEXT NOT NULL,
  PRIMARY KEY (schema_generation, hold_flag)
);
CREATE TABLE incidents (
  incident_id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  status TEXT NOT NULL,
  duplicate_of TEXT,
  hold_flag INTEGER NOT NULL,
  retention_class TEXT NOT NULL,
  closed_at TEXT
);
INSERT INTO hold_flag_semantics VALUES
(8,0,'Not held; deletion still requires exact approval','2026-08-12'),
(8,1,'Mandatory legal preservation','2026-08-12');
INSERT INTO incidents VALUES
('INC-BASE-100','Payment latency investigation','Closed',NULL,0,'Operational','2026-07-14T16:00:00Z'),
('INC-BASE-101','Authentication alert review','Closed',NULL,0,'Operational','2026-07-18T11:00:00Z'),
('INC-DUP-219','Duplicate payment latency record','Closed','INC-BASE-100',0,'Operational','2026-07-14T16:05:00Z'),
('INC-DUP-220','Duplicate authentication alert record','Closed','INC-BASE-101',0,'Operational','2026-07-18T11:04:00Z'),
('INC-HOLD-221','Held duplicate evidence record','Closed','INC-BASE-100',1,'Legal hold','2026-07-14T16:07:00Z'),
('INC-OPEN-222','Active access investigation','Open',NULL,0,'Security',NULL);
