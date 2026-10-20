CREATE TABLE wellness_responses (
  response_id TEXT PRIMARY KEY,
  employee_ref TEXT NOT NULL,
  rating INTEGER,
  completion_state TEXT NOT NULL,
  comment TEXT,
  submitted_at TEXT
);
INSERT INTO wellness_responses VALUES
('SAT-2001','E-201',5,'complete','The coaching sessions were useful.','2026-09-08T10:00:00+08:00'),
('SAT-2002','E-202',4,'complete','The appointment reminders helped.','2026-09-08T10:15:00+08:00'),
('SAT-2003','E-203',2,'complete','Night-shift appointments were repeatedly unavailable.','2026-09-08T10:30:00+08:00'),
('SAT-2004','E-204',3,'complete','The program was adequate but follow-up was slow.','2026-09-08T10:45:00+08:00'),
('SAT-2005','E-205',NULL,'not_started',NULL,NULL),
('SAT-2006','E-206',1,'complete','The exercise plan worsened my pain and I could not reach support.','2026-09-08T11:10:00+08:00');
