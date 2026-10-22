PRAGMA foreign_keys = ON;

CREATE TABLE alert_subscriptions (
    subscription_id TEXT PRIMARY KEY,
    responder_id TEXT NOT NULL,
    responder_name TEXT NOT NULL,
    team TEXT NOT NULL,
    role TEXT NOT NULL,
    qualification_code TEXT NOT NULL,
    phone TEXT NOT NULL,
    zone TEXT NOT NULL,
    shift TEXT NOT NULL,
    channel TEXT NOT NULL,
    active INTEGER NOT NULL CHECK (active IN (0, 1)),
    created_at TEXT NOT NULL,
    roster_revision TEXT NOT NULL
);

INSERT INTO alert_subscriptions VALUES
('SUB-1001', 'RSP-201', 'Elena Park', 'Line 2 Response', 'Fire Warden', 'FW-L2-884', '+86-21-5550-4206', 'L-2', 'day', 'voice_sms', 1, '2026-08-18T09:10:00+08:00', 'REV-2026-09-A'),
('SUB-1007', 'RSP-201', 'Elena Park', 'Line 2 Response', 'Fire Warden', 'FW-L2-884', '+86-21-5550-4206', 'L-2', 'day', 'voice_sms', 1, '2026-08-18T09:10:00+08:00', 'REV-2026-09-A'),
('SUB-1002', 'RSP-202', 'Tomas Reed', 'Warehouse Response', 'First Aid Lead', 'FA-W1-613', '+86-21-5550-5831', 'W-1', 'night', 'voice_sms', 1, '2026-08-19T10:15:00+08:00', 'REV-2026-09-A'),
('SUB-1003', 'RSP-203', 'Priya Nair', 'Utilities Response', 'Electrical Isolator', 'EI-U4-529', '+86-21-5550-6948', 'U-4', 'swing', 'voice_sms', 1, '2026-08-19T11:20:00+08:00', 'REV-2026-09-A'),
('SUB-1004', 'RSP-204', 'Owen Li', 'Line 5 Response', 'Spill Control Lead', 'SC-L5-742', '+86-21-5550-8365', 'L-5', 'night', 'voice_sms', 1, '2026-08-20T08:45:00+08:00', 'REV-2026-09-A'),
('SUB-1009', 'RSP-204', 'Owen Li', 'Line 5 Response', 'Spill Control Lead', 'SC-L5-742', '+86-21-5550-8365', 'L-5', 'night', 'voice_sms', 1, '2026-08-20T08:45:00+08:00', 'REV-2026-09-A'),
('SUB-1011', 'RSP-311', 'Mei Luo', 'Emergency Coordination', 'Fire Warden', 'FW-R3-141', '+86-21-5550-7714', 'R-3', 'day', 'voice_sms', 1, '2026-09-01T07:30:00+08:00', 'REV-2026-09-A'),
('SUB-1012', 'RSP-312', 'Jian Wu', 'Emergency Coordination', 'Incident Commander', 'IC-R3-288', '+86-21-5550-7714', 'R-3', 'night', 'voice_sms', 1, '2026-09-01T07:35:00+08:00', 'REV-2026-09-A'),
('SUB-1013', 'RSP-313', 'Sara Chen', 'Emergency Coordination', 'Hazmat Responder', 'HZ-R3-377', '+86-21-5550-7714', 'R-3', 'swing', 'voice_sms', 1, '2026-09-01T07:40:00+08:00', 'REV-2026-09-A');
