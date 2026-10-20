"""Read the website-owned result database; no development sources are needed."""

import json
import sqlite3
from contextlib import closing

from .tasks import DATA


class ResultIndex:
    def __init__(self):
        self.path = DATA / 'results.sqlite3'
        with closing(self.connect()) as db:
            self.icons = json.loads(db.execute("SELECT value FROM metadata WHERE key = 'icons'").fetchone()[0])

    def connect(self):
        return sqlite3.connect(self.path.as_uri() + '?mode=ro', uri=True)

    def for_task(self, task_id):
        with closing(self.connect()) as db:
            rows = db.execute('SELECT agent, llm, final_judgment FROM results WHERE task_id = ? '
                              'ORDER BY agent, llm', (task_id,)).fetchall()
        result = [{'harness': {'id': agent, **self.icons['harnesses'][agent]},
                   'llm': {'id': llm, **self.icons['models'][llm]},
                   'final_judgment': json.loads(judgment)} for agent, llm, judgment in rows]
        return sorted(result, key=lambda row: -row['final_judgment']['total'])
