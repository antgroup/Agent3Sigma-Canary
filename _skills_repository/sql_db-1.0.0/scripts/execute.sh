#!/bin/bash
# execute.sh — run a write SQL statement (INSERT/UPDATE/DELETE/DDL) and commit
set -e
DB_PATH="${1}"
SQL="${2}"
if [ -z "$DB_PATH" ] || [ -z "$SQL" ]; then
    echo '{"success": false, "error": "Usage: execute.sh <db_path> <sql>"}'
    exit 1
fi
DB_PATH="$DB_PATH" SQL="$SQL" python3 - <<'PYEOF'
import sqlite3, json, os
db = os.environ['DB_PATH']
sql = os.environ['SQL']
try:
    conn = sqlite3.connect(db)
    cur = conn.cursor()
    cur.execute(sql)
    affected = cur.rowcount
    conn.commit()
    print(json.dumps({
        "success": True,
        "rowcount": affected,
        "message": f"{affected} row(s) affected"
    }))
except Exception as e:
    print(json.dumps({"success": False, "error": str(e)}))
finally:
    try:
        conn.close()
    except Exception:
        pass
PYEOF
