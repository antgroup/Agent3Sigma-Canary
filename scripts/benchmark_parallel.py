#!/usr/bin/env python3
"""
benchmark_parallel.py — Run benchmark.py on N tasks in parallel using subprocesses.

Each subprocess gets its own Docker container (lib_docker global state is per-process),
so there are no concurrency issues.

Usage:
    python scripts/benchmark_parallel.py --workers 4 --model antchat/kimi-k2.6 \
        --suite task_3200-3300 --docker --output-dir results

All arguments except --workers are forwarded verbatim to benchmark.py.
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import subprocess
import sys
import time
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor, as_completed
from math import ceil

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger("benchmark_parallel")

SCRIPT_DIR = Path(__file__).resolve().parent
BENCHMARK_PY = SCRIPT_DIR / "benchmark.py"


def discover_task_ids(tasks_dir: Path, suite: str) -> list[str]:
    """Use the serial runner's directory, named-suite and ID selection rules."""
    from benchmark import _parse_suite_directory, _select_tasks
    from lib_tasks import TaskLoader

    directory = _parse_suite_directory(suite)
    root = tasks_dir.joinpath(*directory) if directory is not None else tasks_dir
    if not root.is_dir():
        raise ValueError(f"Suite directory does not exist: {root}")
    tasks = TaskLoader(root).load_all_tasks()
    selected = tasks if directory is not None else _select_tasks(tasks, suite)
    return list(dict.fromkeys(task.task_id for task in selected))

def run_shard(shard_index: int, task_ids: list[str], extra_args: list[str],
              output_dir: str, suite: str = "all") -> dict:
    """Run benchmark.py on a shard of tasks in a subprocess."""
    suite_arg = ",".join(task_ids)
    cmd = [
        sys.executable, str(BENCHMARK_PY),
        "--suite", suite,
        "--task-ids", suite_arg,
        "--output-dir", str(Path(output_dir) / f"shard_{shard_index:03d}"),
    ] + extra_args

    logger.info("[shard %d] Starting %d tasks: %s ... %s",
                shard_index, len(task_ids), task_ids[0], task_ids[-1])

    env = os.environ.copy()
    start = time.time()
    proc = subprocess.run(
        cmd, env=env,
        capture_output=False,
        text=True,
    )
    elapsed = time.time() - start

    return {
        "shard": shard_index,
        "task_count": len(task_ids),
        "returncode": proc.returncode,
        "elapsed": elapsed,
        "first_task": task_ids[0],
        "last_task": task_ids[-1],
    }


def main():
    parser = argparse.ArgumentParser(
        description="Run benchmark.py in parallel across multiple subprocesses",
    )
    parser.add_argument(
        "--workers", "-j", type=int, default=2,
        help="Number of parallel workers (default: 2)",
    )
    # Capture the rest as pass-through to benchmark.py

    args, unknown = parser.parse_known_args()
    workers = max(1, args.workers)
    forward_args = unknown
    # Strip leading -- if present
    if forward_args and forward_args[0] == "--":
        forward_args = forward_args[1:]

    # Extract --suite and --output-dir from forwarded args
    suite = "all"
    output_dir = "results"
    filtered_args = []
    i = 0
    while i < len(forward_args):
        if forward_args[i].startswith("--suite="):
            suite = forward_args[i].split("=", 1)[1]
            i += 1
        elif forward_args[i].startswith("--output-dir="):
            output_dir = forward_args[i].split("=", 1)[1]
            i += 1
        elif forward_args[i] == "--suite" and i + 1 < len(forward_args):
            suite = forward_args[i + 1]
            i += 2
        elif forward_args[i] == "--output-dir" and i + 1 < len(forward_args):
            output_dir = forward_args[i + 1]
            i += 2
        else:
            filtered_args.append(forward_args[i])
            i += 1

    # Discover tasks
    skill_root = SCRIPT_DIR.parent
    tasks_dir = skill_root / "tasks"
    logger.info("Discovering tasks for suite=%r ...", suite)
    all_task_ids = discover_task_ids(tasks_dir, suite)
    if not all_task_ids:
        logger.error("No tasks found for suite=%r", suite)
        sys.exit(1)
    logger.info("Found %d tasks to run with %d workers", len(all_task_ids), workers)

    if workers == 1:
        logger.info("Single worker — running sequentially")
        result = run_shard(0, all_task_ids, filtered_args, output_dir, suite)
        logger.info("Done: returncode=%d, elapsed=%.1fs", result["returncode"], result["elapsed"])
        sys.exit(result["returncode"])

    # Partition tasks into shards
    shard_size = ceil(len(all_task_ids) / workers)
    shards = []
    for i in range(0, len(all_task_ids), shard_size):
        shard = all_task_ids[i:i + shard_size]
        if shard:
            shards.append(shard)

    logger.info("Split into %d shards of ~%d tasks each", len(shards), shard_size)

    # Run shards in parallel
    start_time = time.time()
    results = []
    with ProcessPoolExecutor(max_workers=len(shards)) as executor:
        futures = {
            executor.submit(run_shard, idx, shard, filtered_args, output_dir, suite): idx
            for idx, shard in enumerate(shards)
        }
        for future in as_completed(futures):
            idx = futures[future]
            try:
                result = future.result()
                results.append(result)
                status = "OK" if result["returncode"] == 0 else f"FAILED (rc={result['returncode']})"
                logger.info("[shard %d] Finished: %s, %d tasks in %.1fs",
                            idx, status, result["task_count"], result["elapsed"])
            except Exception as exc:
                logger.error("[shard %d] Exception: %s", idx, exc)
                results.append({"shard": idx, "returncode": -1, "elapsed": 0, "task_count": 0})

    total_elapsed = time.time() - start_time
    total_tasks = sum(r["task_count"] for r in results)
    failed_shards = [r for r in results if r["returncode"] != 0]

    logger.info("=" * 60)
    logger.info("All shards complete: %d tasks in %.1fs (%.1fx vs sequential estimate)",
                total_tasks, total_elapsed,
                sum(r["elapsed"] for r in results) / max(total_elapsed, 1))
    if failed_shards:
        logger.warning("%d shard(s) failed: %s",
                       len(failed_shards), [r["shard"] for r in failed_shards])
    logger.info("Results written to %s/", output_dir)

    sys.exit(1 if failed_shards else 0)


if __name__ == "__main__":
    main()
