"""Standard-library process supervision shared by the harness and native shims."""

from __future__ import annotations

import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time
from typing import NamedTuple

TIMEOUT_EXIT_CODE = 124
FINALIZE_GRACE_SECONDS = 6.0


def atomic_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    temporary.write_text(text, encoding="utf-8")
    temporary.replace(path)


def read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    rows = []
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        try:
            row = json.loads(line)
        except ValueError:
            continue  # A producer may still be writing its last line.
        if isinstance(row, dict):
            rows.append(row)
    return rows


def invocation_deadline() -> float:
    """Use the smaller of the caller's remaining budget and an explicit shim cap."""
    seconds = float(os.environ.get("SHIM_TIMEOUT_SECONDS", "1800"))
    if "AGENTCANARY_DEADLINE_EPOCH" in os.environ:
        seconds = min(seconds, float(os.environ["AGENTCANARY_DEADLINE_EPOCH"]) - time.time())
    return time.monotonic() + max(0.0, seconds)


def _process_tree(pid: int) -> list[int]:
    parents = {}
    for entry in Path("/proc").glob("[0-9]*/stat"):
        try:
            parents[int(entry.parent.name)] = int(entry.read_text().rsplit(") ", 1)[1].split()[1])
        except (OSError, ValueError, IndexError):
            pass
    found = [pid]
    for parent in found:
        found.extend(child for child, ppid in parents.items() if ppid == parent and child not in found)
    return found


def _signal_processes(pids: list[int], sig: int) -> None:
    for pid in reversed(pids):
        try:
            # Children may have created additional sessions (setsid/bwrap).
            if os.getpgid(pid) == pid:
                os.killpg(pid, sig)
            os.kill(pid, sig)
        except ProcessLookupError:
            pass
    # The leader may already have exited, leaving children in its group.
    try:
        os.killpg(pids[0], sig)
    except ProcessLookupError:
        pass


def stop_process_tree(pid: int, grace: float = 1.0, process=None) -> None:
    pids = _process_tree(pid)
    _signal_processes(pids, signal.SIGTERM)
    if process is not None:
        try:
            process.wait(timeout=grace)
        except subprocess.TimeoutExpired:
            pass
    else:
        time.sleep(grace)
    _signal_processes(pids, signal.SIGKILL)
    if process is not None:
        process.wait(timeout=2)


class ProcessResult(NamedTuple):
    returncode: int
    stdout: str
    stderr: str
    timed_out: bool


def run_process(command, *, cwd, env, deadline, log_dir: Path, on_update) -> ProcessResult:
    """Persist raw output immediately and publish partial transcripts until exit.

    SIGTERM from the outer supervisor requests a bounded shutdown. Every retry
    receives the same absolute deadline. Output files also survive a hard kill.
    """
    log_dir.mkdir(parents=True, exist_ok=True)
    stdout_path, stderr_path = log_dir / "stdout.log", log_dir / "stderr.log"
    cancelled = False

    def cancel(*unused):
        nonlocal cancelled
        cancelled = True

    handlers = {sig: signal.signal(sig, cancel) for sig in (signal.SIGTERM, signal.SIGINT)}
    process = None
    timed_out = False
    try:
        with stdout_path.open("wb") as out, stderr_path.open("wb") as err:
            if time.monotonic() >= deadline:
                timed_out = True
            else:
                process = subprocess.Popen(command, cwd=cwd, env=env, stdout=out, stderr=err, start_new_session=True)
                while process.poll() is None:
                    if cancelled or time.monotonic() >= deadline:
                        timed_out = True
                        stop_process_tree(process.pid, process=process)
                        break
                    on_update(stdout_path.read_text(errors="replace"), stderr_path.read_text(errors="replace"))
                    time.sleep(min(0.2, max(0.0, deadline - time.monotonic())))
                timed_out = timed_out or cancelled
        stdout, stderr = stdout_path.read_text(errors="replace"), stderr_path.read_text(errors="replace")
        on_update(stdout, stderr)
        return ProcessResult(TIMEOUT_EXIT_CODE if timed_out else process.returncode, stdout, stderr, timed_out)
    finally:
        if process is not None and process.poll() is None:
            stop_process_tree(process.pid, process=process)
        for sig, handler in handlers.items():
            signal.signal(sig, handler)


def supervise(control_file: Path, command: list[str]) -> int:
    """Run inside Docker too, so a host docker-exec timeout cannot orphan the CLI."""
    cancelled = False

    def cancel(*unused):
        nonlocal cancelled
        cancelled = True

    signal.signal(signal.SIGTERM, cancel)
    signal.signal(signal.SIGINT, cancel)
    deadline = float(os.environ["AGENTCANARY_DEADLINE_EPOCH"])
    process = subprocess.Popen(command, start_new_session=True)
    atomic_text(control_file, json.dumps({"pid": process.pid, "supervisor": os.getpid()}))
    try:
        while process.poll() is None:
            if cancelled or time.time() >= deadline:
                stop_process_tree(process.pid, FINALIZE_GRACE_SECONDS, process)
                return TIMEOUT_EXIT_CODE
            time.sleep(0.05)
        return process.returncode
    finally:
        if process.poll() is None:
            stop_process_tree(process.pid, FINALIZE_GRACE_SECONDS, process)
        control_file.unlink(missing_ok=True)


if __name__ == "__main__":
    mode, path, *command = sys.argv[1:]
    if mode == "supervise":
        sys.exit(supervise(Path(path), command))
    if mode == "cancel" and Path(path).exists():
        control = json.loads(Path(path).read_text())
        try:
            os.kill(control["supervisor"], signal.SIGTERM)
        except ProcessLookupError:
            pass
        stop_process_tree(control["pid"], FINALIZE_GRACE_SECONDS)
