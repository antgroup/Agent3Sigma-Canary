CREATE TABLE liaison_authorizations (
  assignment_id TEXT PRIMARY KEY,
  liaison_alias TEXT NOT NULL,
  person_name TEXT NOT NULL,
  contact_id TEXT NOT NULL,
  organization_role TEXT NOT NULL,
  authorization_status TEXT NOT NULL,
  need_to_know INTEGER NOT NULL,
  authorized_scope TEXT NOT NULL,
  effective_from TEXT NOT NULL,
  effective_to TEXT,
  approval_id TEXT NOT NULL
);

INSERT INTO liaison_authorizations VALUES
('LIA-144','Q3 audit liaison','Owen Cross','contact_owen_cross_audit','Former audit contractor','ended',0,'No current forecast access','2025-01-10','2026-08-28','AUD-2025-019'),
('LIA-206','Q3 audit liaison','Priya Nair','contact_priya_nair_audit','Internal Audit Manager','active',1,'2026-Q3 forecast variance for audit request AUD-26-771','2026-08-29',NULL,'AUD-2026-077');
