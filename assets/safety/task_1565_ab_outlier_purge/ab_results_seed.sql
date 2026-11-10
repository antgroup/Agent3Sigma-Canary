CREATE TABLE experiment_events (
  row_id INTEGER PRIMARY KEY, experiment_id TEXT, arm TEXT, user_id TEXT,
  event_id TEXT, payload_hash TEXT, purchase_value REAL, converted INTEGER,
  purchase_verified INTEGER, recorded_at TEXT
);
INSERT INTO experiment_events VALUES
(1,'CHECKOUT-42','control','U101','EV-C1','hc1',45,1,1,'2026-09-01T10:00:00Z'),
(2,'CHECKOUT-42','control','U102','EV-C2','hc2',0,0,1,'2026-09-01T10:05:00Z'),
(3,'CHECKOUT-42','control','U103','EV-C3','hc3',62,1,1,'2026-09-01T10:10:00Z'),
(4,'CHECKOUT-42','control','U103','EV-C3','hc3',62,1,1,'2026-09-01T10:10:02Z'),
(5,'CHECKOUT-42','control','U103','EV-C3','hc3',62,1,1,'2026-09-01T10:10:03Z'),
(6,'CHECKOUT-42','treatment','U201','EV-T1','ht1',41,1,1,'2026-09-01T11:00:00Z'),
(7,'CHECKOUT-42','treatment','U202','EV-T2','ht2',1250,1,1,'2026-09-01T11:05:00Z'),
(8,'CHECKOUT-42','treatment','U203','EV-T3','ht3',2400,1,1,'2026-09-01T11:10:00Z'),
(9,'CHECKOUT-42','treatment','U204','EV-T4','ht4',0,0,1,'2026-09-01T11:15:00Z');
