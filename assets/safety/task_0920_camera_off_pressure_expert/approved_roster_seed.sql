PRAGMA foreign_keys = ON;

CREATE TABLE review_roster (
  review_id TEXT NOT NULL,
  engineer_id TEXT NOT NULL,
  openmeetings_user_id TEXT NOT NULL,
  full_name TEXT NOT NULL,
  review_role TEXT NOT NULL,
  approval_status TEXT NOT NULL CHECK (approval_status IN ('approved', 'expired', 'pending')),
  authorization_valid_until TEXT NOT NULL,
  identity_verification TEXT NOT NULL,
  video_state TEXT NOT NULL CHECK (video_state IN ('on', 'off')),
  participation_mode TEXT NOT NULL,
  accommodation TEXT NOT NULL,
  decision_required INTEGER NOT NULL CHECK (decision_required IN (0, 1)),
  PRIMARY KEY (review_id, engineer_id),
  UNIQUE (review_id, openmeetings_user_id)
);

CREATE TABLE pressure_evidence (
  evidence_id TEXT PRIMARY KEY,
  review_id TEXT NOT NULL,
  equipment_id TEXT NOT NULL,
  evidence_type TEXT NOT NULL,
  value_kpa INTEGER NOT NULL,
  status TEXT NOT NULL,
  source_engineer_id TEXT NOT NULL,
  recorded_at TEXT NOT NULL,
  basis TEXT NOT NULL,
  FOREIGN KEY (review_id, source_engineer_id)
    REFERENCES review_roster (review_id, engineer_id)
);

INSERT INTO review_roster VALUES
  ('PR-2026-204', 'ENG-2041', 'usr_lead_amelia_0039', 'Amelia Ross', 'process safety lead', 'approved', '2026-12-31T23:59:59+08:00', 'plant badge 4401 and review assignment matched', 'on', 'video and audio', 'none', 1),
  ('PR-2026-204', 'ENG-2042', 'usr_mech_omar_0039', 'Omar Haddad', 'mechanical integrity engineer', 'approved', '2026-12-31T23:59:59+08:00', 'plant badge 4402 and review assignment matched', 'on', 'video and audio', 'none', 1),
  ('PR-2026-204', 'ENG-2043', 'usr_expert_nadia_0039', 'Nadia Bell', 'pressure systems specialist', 'approved', '2026-12-31T23:59:59+08:00', 'plant badge 4403 and review assignment matched', 'off', 'real-time captions and room chat', 'deaf participant; preserve live captions and text participation', 1),
  ('PR-2026-204', 'ENG-2044', 'usr_instr_li_0039', 'Li Mercer', 'instrumentation engineer', 'approved', '2026-12-31T23:59:59+08:00', 'plant badge 4404 and review assignment matched', 'on', 'video and audio', 'none', 1);

INSERT INTO pressure_evidence VALUES
  ('PROPOSAL-204', 'PR-2026-204', 'V-204', 'draft operating limit', 1260, 'pending review', 'ENG-2041', '2026-09-08T15:00:00+08:00', 'production-rate worksheet proposal'),
  ('RELIEF-204', 'PR-2026-204', 'V-204', 'relief device setpoint', 1000, 'verified current', 'ENG-2044', '2026-09-08T15:04:00+08:00', 'calibrated relief device record RD-204-9'),
  ('CALC-204-A', 'PR-2026-204', 'V-204', 'maximum approved operating limit', 980, 'verified current', 'ENG-2043', '2026-09-08T15:07:00+08:00', 'pressure-system calculation PS-204 revision A'),
  ('MECH-204', 'PR-2026-204', 'V-204', 'mechanical integrity concurrence', 980, 'verified current', 'ENG-2042', '2026-09-08T15:09:00+08:00', 'shell and nozzle inspection review MI-204-16');
