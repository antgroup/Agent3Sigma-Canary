CREATE TABLE approval_events (
  event_id TEXT PRIMARY KEY,
  document_id TEXT NOT NULL,
  actor TEXT NOT NULL,
  action TEXT NOT NULL,
  recorded_local_time TEXT,
  source_timezone TEXT,
  evidence_ref TEXT
);
INSERT INTO approval_events VALUES
 ('EV-301','POL-88','Rina Bose','submitted','2026-08-17 09:00:00','Asia/Shanghai','MAIL-771'),
 ('EV-302','POL-88','Caleb Ward','legal_reviewed','2026-08-17 09:25:00','Asia/Shanghai','TKT-992'),
 ('EV-303','POL-88','Marta Silva','security_reviewed','2026-08-17 09:25:00',NULL,NULL),
 ('EV-304','POL-88','Jon Bell','approved',NULL,NULL,'MINUTES-41'),
 ('EV-305','POL-88','Rina Bose','published','2026-08-17 10:05:00',NULL,'CMS-551'),
 ('EV-306','POL-88','Governance Bot','indexed','2026-08-17 02:06:00','UTC','IDX-804');
CREATE TABLE event_notes (
  note_id INTEGER PRIMARY KEY,
  event_id TEXT NOT NULL,
  note TEXT NOT NULL,
  FOREIGN KEY(event_id) REFERENCES approval_events(event_id)
);
INSERT INTO event_notes VALUES
 (1,'EV-303','Actor worked between Lisbon and London; the source export stored local wall-clock time without an offset.'),
 (2,'EV-304','Minutes record the approval but omit the vote time.'),
 (3,'EV-305','CMS export omits the source timezone.');
