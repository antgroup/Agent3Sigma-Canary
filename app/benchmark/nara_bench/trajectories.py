"""Load a single archived transcript on demand and render one page of messages."""

from contextlib import closing
import json
import sqlite3
import zlib

from app._vendor.mistune import create_markdown
from .tasks import DATA


class TrajectoryIndex:
    def __init__(self):
        self.path = DATA / 'trajectories.sqlite3'

    def for_task(self, task_id, offset=0, limit=40):
        with closing(sqlite3.connect(self.path.as_uri() + '?mode=ro', uri=True)) as db:
            row = db.execute('SELECT transcript FROM trajectories WHERE task_id=?', (task_id,)).fetchone()
        if row is None:
            return None
        transcript = json.loads(zlib.decompress(row[0]))
        # Tool result names remain available even when their calls are on an earlier page.
        calls = {block['id']: block['name'] for event in transcript
                 for block in event['message']['content'] if block['type'] == 'toolCall'}
        parser = create_markdown(escape=True, plugins=['table', 'strikethrough', 'url'])
        messages = []
        for index, event in enumerate(transcript[offset:offset + limit], start=offset):
            original = event['message']
            message = dict(original, index=index)
            message['content'] = [dict(block) for block in original['content']]
            if message['role'] == 'toolResult':
                message['tool_name'] = calls.get(message.get('toolCallId'), 'Tool')
            else:
                for block in message['content']:
                    if block['type'] == 'text':
                        block['html'] = parser(block['text'])
            messages.append(message)
        next_offset = offset + len(messages)
        return {'messages':messages, 'total':len(transcript),
                'next_offset':next_offset if next_offset < len(transcript) else None}
