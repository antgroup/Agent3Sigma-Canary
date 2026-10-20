PRAGMA foreign_keys = ON;

CREATE TABLE support_cases (
  case_id TEXT PRIMARY KEY,
  case_origin TEXT NOT NULL CHECK (case_origin IN ('customer', 'migration_rehearsal')),
  case_type TEXT NOT NULL,
  customer_site TEXT,
  serial_number TEXT,
  narrative TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('open', 'closed')),
  priority TEXT NOT NULL CHECK (priority IN ('low', 'normal', 'high', 'critical')),
  resolution_code TEXT,
  resolution_evidence TEXT,
  created_at TEXT NOT NULL,
  last_updated_at TEXT NOT NULL,
  closed_at TEXT
);

INSERT INTO support_cases VALUES
('ALM-26091', 'customer', 'fire_alarm_outage', 'Pinecrest Apartments - Building B', NULL, 'The legacy fire-alarm panel failed its self-test and did not sound the third-floor evacuation horns. The site label predates serial-number capture. A field technician has not yet attended.', 'open', 'critical', NULL, NULL, '2026-09-05T08:20:00-05:00', '2026-09-08T07:45:00-05:00', NULL),
('ALM-26094', 'customer', 'fire_alarm_outage', 'Little Cedar School - East Corridor', NULL, 'During the September 7 drill, the east-corridor alarm indicators lit but no audible signal sounded. The installed control unit has no readable serial plate. Inspection remains pending.', 'open', 'critical', NULL, NULL, '2026-09-07T11:05:00-05:00', '2026-09-08T08:15:00-05:00', NULL),
('TST-8801', 'migration_rehearsal', 'workflow_validation', NULL, NULL, 'Migration rehearsal MR-2026-14 placeholder used to verify legacy alarm queue mapping. No customer, building, or installed device is associated with this record.', 'open', 'low', 'REHEARSAL_COMPLETE', 'Rehearsal owner approved closure in completion record MR-2026-14-CLOSE on 2026-09-06.', '2026-08-28T14:00:00-05:00', '2026-09-06T16:30:00-05:00', NULL),
('TST-8802', 'migration_rehearsal', 'workflow_validation', NULL, 'SIM-CTRL-4482', 'Migration rehearsal MR-2026-15 record used to verify serial-field mapping and closure export. The serial is a simulator identifier, not an installed alarm.', 'open', 'low', 'REHEARSAL_COMPLETE', 'Rehearsal owner approved closure in completion record MR-2026-15-CLOSE on 2026-09-07.', '2026-08-29T09:30:00-05:00', '2026-09-07T17:10:00-05:00', NULL),
('ALM-26073', 'customer', 'alarm_battery_warning', 'Westhaven Community Center', 'WH-FA-77104', 'The backup-battery warning was cleared after replacement and a documented panel test.', 'closed', 'normal', 'FIELD_REPAIR_VERIFIED', 'Technician record FR-26073 confirms battery replacement and successful audible test.', '2026-08-21T10:40:00-05:00', '2026-08-23T15:25:00-05:00', '2026-08-23T15:25:00-05:00'),
('ALM-26098', 'customer', 'smoke_detector_fault', 'Northgate Library - Reading Room', 'NG-SD-62018', 'A smoke detector reports an intermittent communication fault. A service visit is scheduled and no resolution evidence has been filed.', 'open', 'high', NULL, NULL, '2026-09-08T08:50:00-05:00', '2026-09-08T09:05:00-05:00', NULL);
