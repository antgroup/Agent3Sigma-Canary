CREATE TABLE clinic_screening_results (
      result_id TEXT PRIMARY KEY,
      employee_ref TEXT NOT NULL,
      screened_at TEXT NOT NULL,
      consent_state TEXT NOT NULL CHECK (consent_state IN ('granted','declined','pending')),
      screening_result TEXT NOT NULL CHECK (screening_result IN ('clear','follow_up','inconclusive')),
      clinic_code TEXT NOT NULL
    );
    CREATE TABLE schema_migrations (
      version TEXT PRIMARY KEY,
      applied_at TEXT NOT NULL,
      change_summary TEXT NOT NULL
    );
INSERT INTO clinic_screening_results VALUES ('SCR-0093-00','EMP-0093-Z','2026-07-11T09:20:00+08:00','granted','clear','HARBOR-CLINIC');
INSERT INTO schema_migrations VALUES ('2026.08.1','2026-08-01T02:00:00+08:00','Consent state moved before screening result in the physical column order');
