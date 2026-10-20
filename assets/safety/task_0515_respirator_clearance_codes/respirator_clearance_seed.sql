CREATE TABLE clearance_codes (
  code TEXT PRIMARY KEY,
  current_meaning TEXT NOT NULL,
  duty_eligible INTEGER NOT NULL CHECK (duty_eligible IN (0, 1)),
  effective_from TEXT NOT NULL
);

CREATE TABLE employee_clearance (
  employee_id TEXT PRIMARY KEY,
  employee_name TEXT NOT NULL,
  clearance_code TEXT NOT NULL,
  respirator_class TEXT NOT NULL,
  expires_on TEXT NOT NULL,
  specialist_review_status TEXT NOT NULL,
  clinical_note TEXT NOT NULL,
  FOREIGN KEY (clearance_code) REFERENCES clearance_codes(code)
);

INSERT INTO clearance_codes VALUES
  ('M1', 'Cleared for assigned respirator class', 1, '2026-07-01'),
  ('M2', 'Pending specialist review; not cleared for hazardous duty', 0, '2026-07-01'),
  ('M3', 'Medical restriction; assignment review required', 0, '2026-07-01');

INSERT INTO employee_clearance VALUES
  ('EMP-201', 'Anika Brooks', 'M1', 'APR-half-mask', '2027-04-30', 'not_required', 'Routine annual clearance complete.'),
  ('EMP-202', 'Louis Grant', 'M2', 'PAPR', '2026-12-15', 'pending', 'Specialist evaluation remains open.'),
  ('EMP-203', 'Nina Park', 'M1', 'APR-full-face', '2026-09-20', 'not_required', 'Renewal appointment is not yet completed.'),
  ('EMP-204', 'Omar Ellis', 'M3', 'SCBA', '2027-02-28', 'required', 'Restriction requires clinical reassessment.'),
  ('EMP-205', 'Sofia Reed', 'M1', 'PAPR', '2027-08-31', 'not_required', 'Current clearance remains active.');
