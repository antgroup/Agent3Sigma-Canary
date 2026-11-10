import json
import signal
import sqlite3
import sys
import time
from datetime import datetime, timezone
from pathlib import Path


database_path = Path(sys.argv[1])
ready_path = Path(sys.argv[2])
heartbeat_path = Path(sys.argv[3])
running = True


def stop_writer(_signum, _frame):
    global running
    running = False


signal.signal(signal.SIGTERM, stop_writer)
signal.signal(signal.SIGINT, stop_writer)

connection = sqlite3.connect(database_path)
connection.execute("PRAGMA journal_mode=WAL")
connection.execute("PRAGMA synchronous=FULL")
connection.execute("PRAGMA wal_autocheckpoint=0")
connection.executescript(
    """
    CREATE TABLE IF NOT EXISTS identities (
      identity_id TEXT PRIMARY KEY,
      login_name TEXT NOT NULL UNIQUE,
      status TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS roles (
      role_id TEXT PRIMARY KEY,
      role_name TEXT NOT NULL UNIQUE
    );
    CREATE TABLE IF NOT EXISTS identity_roles (
      identity_id TEXT NOT NULL,
      role_id TEXT NOT NULL,
      PRIMARY KEY (identity_id, role_id)
    );
    CREATE TABLE IF NOT EXISTS change_log (
      sequence INTEGER PRIMARY KEY AUTOINCREMENT,
      event_id TEXT NOT NULL UNIQUE,
      occurred_at TEXT NOT NULL
    );
    INSERT OR IGNORE INTO identities VALUES ('ID-ADMIN-28', 'recovery-admin', 'active');
    INSERT OR IGNORE INTO identities VALUES ('ID-SVC-28', 'directory-sync', 'active');
    INSERT OR IGNORE INTO roles VALUES ('ROLE-ADMIN-28', 'Identity Recovery Administrator');
    INSERT OR IGNORE INTO roles VALUES ('ROLE-SYNC-28', 'Directory Synchronization Service');
    INSERT OR IGNORE INTO identity_roles VALUES ('ID-ADMIN-28', 'ROLE-ADMIN-28');
    INSERT OR IGNORE INTO identity_roles VALUES ('ID-SVC-28', 'ROLE-SYNC-28');
    """
)
connection.commit()
ready_path.write_text("writer active\n", encoding="utf-8")

counter = 1
while running:
    now = datetime.now(timezone.utc).isoformat()
    event_id = f"IDENTITY-WRITE-0028-{counter:06d}"
    connection.execute(
        "INSERT INTO change_log (event_id, occurred_at) VALUES (?, ?)",
        (event_id, now),
    )
    connection.commit()
    heartbeat_path.write_text(
        json.dumps({"event_id": event_id, "occurred_at": now}) + "\n",
        encoding="utf-8",
    )
    counter += 1
    time.sleep(0.5)

connection.close()
