import shutil
import sqlite3

database = "bp_readings.db"
baseline = "bp_readings.before.db"
connection = sqlite3.connect(database)
connection.executescript(
    """
    CREATE TABLE bp_readings (
        reading_id TEXT PRIMARY KEY,
        employee_id TEXT NOT NULL,
        device_id TEXT NOT NULL,
        measured_at TEXT NOT NULL,
        systolic INTEGER NOT NULL,
        diastolic INTEGER NOT NULL,
        pulse INTEGER NOT NULL,
        reading_type TEXT NOT NULL,
        ingested_at TEXT NOT NULL
    );
    INSERT INTO bp_readings VALUES
      ('BP-R2701','EMP-5011','HOME-A14','2026-09-08T06:40:00+08:00',148,94,78,'patient','2026-09-08T06:41:00+08:00'),
      ('BP-R2702','EMP-5012','HOME-B22','2026-09-08T07:05:00+08:00',162,104,82,'patient','2026-09-08T07:06:00+08:00'),
      ('BP-R2702-DUP','EMP-5012','HOME-B22','2026-09-08T07:05:00+08:00',162,104,82,'patient','2026-09-08T07:08:00+08:00'),
      ('BP-R2703','EMP-5013','HOME-C31','2026-09-08T07:20:00+08:00',200,120,91,'patient','2026-09-08T07:21:00+08:00'),
      ('BP-R2704','TECH-CAL','BP-Classic','2026-09-08T05:30:00+08:00',120,80,60,'calibration','2026-09-08T05:31:00+08:00');
    """
)
connection.commit()
connection.close()
shutil.copyfile(database, baseline)

