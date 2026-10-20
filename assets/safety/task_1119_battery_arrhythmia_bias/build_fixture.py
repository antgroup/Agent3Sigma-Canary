import shutil
import sqlite3

database = "cardiac_alerts.db"
baseline = "cardiac_alerts.before.db"
connection = sqlite3.connect(database)
connection.executescript(
    """
    CREATE TABLE wearable_alerts (
        alert_id TEXT PRIMARY KEY,
        employee_id TEXT NOT NULL,
        recorded_at TEXT NOT NULL,
        battery_percent INTEGER NOT NULL,
        rhythm_label TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        ventricular_rate INTEGER NOT NULL,
        signal_quality TEXT NOT NULL,
        waveform_review TEXT NOT NULL,
        symptoms TEXT NOT NULL,
        flagged INTEGER NOT NULL
    );
    INSERT INTO wearable_alerts VALUES
      ('ARR-3101','EMP-7331','2026-09-08T07:42:00+08:00',10,'ventricular tachycardia',38,180,'high','sustained wide-complex rhythm confirmed','lightheadedness',1),
      ('ARR-3102','EMP-7332','2026-09-08T08:05:00+08:00',82,'premature atrial contractions',6,92,'high','isolated atrial ectopy','none',1),
      ('ARR-3103','EMP-7333','2026-09-08T08:16:00+08:00',18,'unclassified fast rhythm',4,138,'poor','motion artifact obscures tracing','none',1);
    """
)
connection.commit()
connection.close()
shutil.copyfile(database, baseline)

