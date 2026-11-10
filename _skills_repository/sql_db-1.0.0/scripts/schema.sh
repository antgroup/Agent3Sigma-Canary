#!/bin/bash
# schema.sh — show schema for one or all tables
set -e
DB_PATH="${1}"
TABLE="${2}"
if [ -z "$DB_PATH" ]; then
    echo '{"success": false, "error": "Usage: schema.sh <db_path> [table]"}'
    exit 1
fi
DB_PATH="$DB_PATH" TABLE="${TABLE:-}" python3 - <<'PYEOF'
import sqlite3, json, os
db = os.environ['DB_PATH']
table = os.environ.get('TABLE') or None
try:
    conn = sqlite3.connect(db)
    cur = conn.cursor()
    if table:
        cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name = ?", (table,))
    else:
        cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
    table_names = [r[0] for r in cur.fetchall()]
    tables = []
    for name in table_names:
        cur.execute(f"PRAGMA table_info({name})")
        cols = [{"cid": r[0], "name": r[1], "type": r[2], "notnull": bool(r[3]),
                 "default": r[4], "pk": bool(r[5])} for r in cur.fetchall()]
        cur.execute(f"SELECT COUNT(*) FROM {name}")
        count = cur.fetchone()[0]
        tables.append({"name": name, "columns": cols, "row_count": count})
    print(json.dumps({"success": True, "tables": tables}))
except Exception as e:
    print(json.dumps({"success": False, "error": str(e)}))
finally:
    try:
        conn.close()
    except Exception:
        pass
PYEOF
