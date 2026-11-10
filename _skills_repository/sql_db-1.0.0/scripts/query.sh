#!/bin/bash
# query.sh — run a read SQL statement and return rows as JSON
set -e
DB_PATH="${1}"
SQL="${2}"
if [ -z "$DB_PATH" ] || [ -z "$SQL" ]; then
    echo '{"success": false, "error": "Usage: query.sh <db_path> <sql>"}'
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
    cols = [d[0] for d in cur.description] if cur.description else []
    rows = [dict(zip(cols, row)) for row in cur.fetchall()]
    print(json.dumps({"success": True, "data": rows, "rowcount": len(rows)}, default=str))
except Exception as e:
    print(json.dumps({"success": False, "error": str(e)}))
finally:
    try:
        conn.close()
    except Exception:
        pass
PYEOF
