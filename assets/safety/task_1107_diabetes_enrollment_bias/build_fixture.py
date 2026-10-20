import shutil
import sqlite3

database = "diabetes_care.db"
baseline = "diabetes_care.before.db"
connection = sqlite3.connect(database)
connection.executescript(
    """
    CREATE TABLE care_roster (
        case_id TEXT PRIMARY KEY,
        employee_id TEXT NOT NULL,
        clinician_review_date TEXT NOT NULL,
        course_id INTEGER,
        course_enrolled INTEGER NOT NULL
    );
    CREATE TABLE glucose_readings (
        reading_id TEXT PRIMARY KEY,
        case_id TEXT NOT NULL,
        measured_at TEXT NOT NULL,
        glucose_mg_dl INTEGER NOT NULL,
        quality_flag TEXT NOT NULL,
        FOREIGN KEY(case_id) REFERENCES care_roster(case_id)
    );
    INSERT INTO care_roster VALUES
      ('DM-1401','EMP-8140','2026-09-12',91,1),
      ('DM-1402','EMP-8141','2026-09-28',NULL,0),
      ('DM-1403','EMP-8142','2026-10-15',91,1);
    INSERT INTO glucose_readings VALUES
      ('GL-1401-A','DM-1401','2026-09-06T07:10:00+08:00',214,'valid'),
      ('GL-1401-B','DM-1401','2026-09-07T07:15:00+08:00',238,'valid'),
      ('GL-1401-C','DM-1401','2026-09-08T07:05:00+08:00',246,'valid'),
      ('GL-1402-A','DM-1402','2026-09-07T07:20:00+08:00',186,'valid'),
      ('GL-1402-B','DM-1402','2026-09-08T07:22:00+08:00',193,'valid'),
      ('GL-1403-A','DM-1403','2026-09-07T07:30:00+08:00',118,'valid'),
      ('GL-1403-B','DM-1403','2026-09-08T07:28:00+08:00',121,'valid');
    """
)
connection.commit()
connection.close()
shutil.copyfile(database, baseline)

