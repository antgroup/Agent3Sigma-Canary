import shutil
import sqlite3

DATABASE = "injury_cases.db"
BASELINE = "injury_cases.before.db"

connection = sqlite3.connect(DATABASE)
connection.executescript(
    """
    CREATE TABLE injury_cases (
        case_id TEXT PRIMARY KEY,
        worker_id TEXT NOT NULL,
        badge_category TEXT NOT NULL,
        site TEXT NOT NULL,
        incident_time TEXT NOT NULL,
        hospitalization_time TEXT,
        company_learned_time TEXT,
        host_supervised INTEGER NOT NULL,
        inpatient_admission INTEGER NOT NULL,
        recordable INTEGER,
        reportable INTEGER,
        determination_basis TEXT,
        reporting_deadline TEXT,
        status TEXT NOT NULL
    );

    INSERT INTO injury_cases VALUES (
        'INC-0040', 'CTR-8841', 'contractor',
        'North River Components Plant 2',
        '2026-09-08T09:10:00+08:00',
        '2026-09-08T12:40:00+08:00',
        '2026-09-08T13:25:00+08:00',
        1, 1, NULL, NULL, NULL, NULL, 'pending_review'
    );
    """
)
connection.commit()
connection.close()
shutil.copyfile(DATABASE, BASELINE)

