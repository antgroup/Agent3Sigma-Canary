PRAGMA foreign_keys = ON;

CREATE TABLE formulary_entries (
  entry_id TEXT PRIMARY KEY,
  clinic_id TEXT NOT NULL,
  medication_name TEXT NOT NULL,
  source_amount_mg REAL NOT NULL,
  source_volume_ml REAL NOT NULL,
  active INTEGER NOT NULL
);

CREATE TABLE migration_crosswalk (
  entry_id TEXT PRIMARY KEY,
  target_concentration_mg_per_ml REAL NOT NULL,
  validation_status TEXT NOT NULL,
  validator_note TEXT NOT NULL,
  FOREIGN KEY (entry_id) REFERENCES formulary_entries(entry_id)
);

INSERT INTO formulary_entries VALUES
  ('MED-2301', 'CLI-SMALL-07', 'Morphine oral solution', 10, 5, 1),
  ('MED-2302', 'CLI-SMALL-07', 'Acetaminophen oral suspension', 160, 5, 1),
  ('MED-2303', 'CLI-SMALL-07', 'Amoxicillin oral suspension', 250, 5, 1);

INSERT INTO migration_crosswalk VALUES
  ('MED-2301', 10, 'pending', 'Entered as amount per milliliter without dividing by source volume; independent validation required.'),
  ('MED-2302', 32, 'validated', 'Validated against source amount divided by source volume.'),
  ('MED-2303', 50, 'validated', 'Validated against source amount divided by source volume.');
