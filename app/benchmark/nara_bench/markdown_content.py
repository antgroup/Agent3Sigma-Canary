"""Render task Markdown lazily, with bounded caching and per-file invalidation."""

from collections import OrderedDict
import html
import os
from pathlib import Path
import re
from threading import Lock, local

from app._vendor.mistune import create_markdown

FRONT_MATTER = re.compile(r'^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)')


def signature(stat):
    return (stat.st_dev, stat.st_ino, stat.st_size, stat.st_mtime_ns, stat.st_ctime_ns)


class MarkdownContent:
    def __init__(self, max_entries=256, max_bytes=8 * 1024 * 1024):
        self.max_entries = max_entries
        self.max_bytes = max_bytes
        self._cache = OrderedDict()
        self._cache_lock = Lock()
        self._file_locks = [Lock() for _ in range(32)]
        self._local = local()
        self._bytes = self._hits = self._renders = 0

    def _compile(self, source):
        if not hasattr(self._local, 'parser'):
            self._local.parser = create_markdown(escape=True, plugins=['table', 'strikethrough', 'url', 'task_lists'])
        front = FRONT_MATTER.match(source)
        configuration = ''
        if front:
            configuration = ('<details class="task-configuration"><summary>Task configuration</summary>'
                             '<pre><code class="language-yaml">' + html.escape(front.group(1)) + '</code></pre></details>')
            source = source[front.end():]
        return configuration + self._local.parser(source)

    def render(self, path):
        path = Path(path)
        # Requests for the same task share one compilation; unrelated tasks can render concurrently.
        with self._file_locks[hash(path) % len(self._file_locks)]:
            stamp = signature(path.stat())
            with self._cache_lock:
                cached = self._cache.get(path)
                if cached and cached[0] == stamp:
                    self._cache.move_to_end(path)
                    self._hits += 1
                    return cached[1]
            stable = False
            # Avoid caching a partial read during in-place edits or an atomic file replacement.
            for _ in range(3):
                with path.open('rb') as file:
                    before = signature(os.fstat(file.fileno()))
                    raw = file.read()
                    after = signature(os.fstat(file.fileno()))
                stamp = signature(path.stat())
                if before == after == stamp:
                    stable = True
                    break
            rendered = self._compile(raw.decode('utf-8'))
            size = len(rendered.encode('utf-8'))
            with self._cache_lock:
                self._renders += 1
                old = self._cache.pop(path, None)
                if old:
                    self._bytes -= old[2]
                if stable and size <= self.max_bytes and self.max_entries > 0:
                    self._cache[path] = (stamp, rendered, size)
                    self._bytes += size
                    while len(self._cache) > self.max_entries or self._bytes > self.max_bytes:
                        _, removed = self._cache.popitem(last=False)
                        self._bytes -= removed[2]
            return rendered

    def cache_info(self):
        with self._cache_lock:
            return {'entries':len(self._cache), 'bytes':self._bytes, 'hits':self._hits, 'renders':self._renders}
