#!/usr/bin/env python3
"""
AgentScry - OpenClaw Agent Benchmarking System

This script orchestrates benchmarking of OpenClaw agents using tasks loaded
from the tasks/ directory.
"""
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "pyyaml>=6.0.1",
#     "openai>=1.0.0",
# ]
# ///

# Add project root to sys.path before any imports
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import argparse
import json
import logging
import os
import re
import statistics
import subprocess
import sys
import time
import traceback
import uuid
from pathlib import Path
from typing import Dict, List, Optional, Any

import lib_docker as docker
from lib_agent import (
    cleanup_agent_sessions,
    ensure_agent_exists,
    execute_openclaw_task,
    slugify_model,
)
from lib_attacks import get_attack_method, validate_attack_compatibility
from lib_grading import GradeResult, grade_task
from lib_tasks import Task, TaskLoader


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(sys.stdout), logging.FileHandler("benchmark.log")],
)

logger = logging.getLogger("benchmark")


class OpenClawAgent:
    """Scaffold for OpenClaw agent creation and execution."""

    def __init__(self, agent_id: str, config: Optional[Dict[str, Any]] = None):
        self.agent_id = agent_id
        self.config = config or {}
        logger.info(f"Initialized OpenClawAgent: {agent_id}")

    def execute_task(self, task: Task, simulate: bool = False) -> Dict[str, Any]:
        """
        Execute a task with this agent.

        Args:
            task: The Task object to execute
            simulate: If True, simulates execution for demonstration

        Returns:
            Dictionary containing execution results
        """
        if simulate:
            logger.info("Simulate flag no longer supported for execute_task")
        raise NotImplementedError("Use execute_openclaw_task helper for real runs")


class BenchmarkRunner:
    """Orchestrates benchmark execution across tasks and agents."""

    def __init__(self, tasks_dir: Path):
        self.task_loader = TaskLoader(tasks_dir)
        self.tasks: List[Task] = []
        self.agents: List[OpenClawAgent] = []
        logger.info("Initialized BenchmarkRunner")

    def load_tasks(self, verbose: bool = False) -> None:
        """Load all tasks from the tasks directory."""
        logger.info("Loading tasks...")
        self.tasks = self.task_loader.load_all_tasks(verbose=verbose)
        logger.info(f"Loaded {len(self.tasks)} tasks")

    def create_agent(self, agent_id: str, config: Optional[Dict[str, Any]] = None) -> OpenClawAgent:
        """
        Create a new OpenClaw agent for benchmarking.

        Args:
            agent_id: Unique identifier for the agent
            config: Optional configuration dictionary

        Returns:
            OpenClawAgent instance
        """
        logger.info(f"Creating agent: {agent_id}")
        agent = OpenClawAgent(agent_id, config)
        self.agents.append(agent)
        return agent

    def run_benchmark(
        self, agent: OpenClawAgent, task_ids: Optional[List[str]] = None, simulate: bool = False
    ) -> List[Dict[str, Any]]:
        """
        Run benchmark for an agent on specified tasks.

        Args:
            agent: The OpenClawAgent to benchmark
            task_ids: Optional list of task IDs to run. If None, runs all tasks.
            simulate: If True, simulates execution for demonstration

        Returns:
            List of result dictionaries
        """
        # Filter tasks if specific IDs provided
        if task_ids:
            tasks_to_run = [t for t in self.tasks if t.task_id in task_ids]
            logger.info(f"🎯 Running benchmark on {len(tasks_to_run)} specified tasks")
        else:
            tasks_to_run = self.tasks
            logger.info(f"🎯 Running benchmark on all {len(tasks_to_run)} tasks")

        results = []
        for i, task in enumerate(tasks_to_run, 1):
            logger.info(f"\n{'=' * 80}")
            logger.info(f"📋 Task {i}/{len(tasks_to_run)}")
            logger.info(f"{'=' * 80}")
            result = agent.execute_task(task, simulate=simulate)
            results.append(result)

        logger.info(f"\n{'=' * 80}")
        logger.info(f"✨ Benchmark complete! Executed {len(results)} tasks")
        logger.info(f"{'=' * 80}")

        # Print summary
        total_time = sum(r["execution_time"] for r in results)
        logger.info(f"\n📊 BENCHMARK SUMMARY")
        logger.info(f"   Agent: {agent.agent_id}")
        logger.info(f"   Tasks completed: {len(results)}")
        logger.info(f"   Total execution time: {total_time:.2f}s")
        logger.info(f"   Average time per task: {total_time / len(results):.2f}s")

        return results

    def print_task_summary(self) -> None:
        """Print a summary of all loaded tasks."""
        if not self.tasks:
            logger.warning("No tasks loaded")
            return

        print("\n" + "=" * 80)
        print(f"LOADED TASKS SUMMARY ({len(self.tasks)} tasks)")
        print("=" * 80)

        for task in self.tasks:
            print(f"\n[{task.task_id}] {task.name}")
            print(f"  Category: {task.category}")
            print(f"  Grading: {task.grading_type}")
            print(f"  Timeout: {task.timeout_seconds}s")
            print(f"  Criteria: {len(task.grading_criteria)} items")
            print(
                f"  Prompt: {task.prompt[:100]}..."
                if len(task.prompt) > 100
                else f"  Prompt: {task.prompt}"
            )

        print("\n" + "=" * 80)


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="AgentScry OpenClaw Benchmark Runner")
    parser.add_argument(
        "--model",
        required=False,
        help="Model identifier (e.g., anthropic/claude-sonnet-4)",
    )
    parser.add_argument(
        "--suite",
        default="all",
        help='Tasks to run: "all", "automated-only", "direct", "indirect", "non-security", "fptest", "memory", "chain", "skills_poison_EN" or comma-separated IDs',
    )
    parser.add_argument(
        "--output-dir",
        default="results",
        help="Results directory",
    )
    parser.add_argument(
        "--timeout-multiplier",
        type=float,
        default=3.0,
        help="Scale all task timeouts",
    )
    parser.add_argument(
        "--runs",
        type=int,
        default=1,
        help="Number of runs per task for averaging",
    )
    parser.add_argument(
        "--judge",
        default=None,
        help="Deprecated compatibility option; configure the judge model with JUDGE_LLM_MODEL via config.yaml/env.sh",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable verbose logging (shows transcript contents, workspace files, etc.)",
    )
    parser.add_argument(
        "--no-fail-fast",
        action="store_true",
        help="Continue running all tasks even if sanity check scores 0%%",
    )
    parser.add_argument(
        "--attack",
        type=str,
        default=None,
        help="Attack method to apply (e.g., code_attack, important_message, InjecAgent, Ignore, pair, ipi_payload[:strategy])",
    )
    parser.add_argument(
        "--no-context",
        action="store_true",
        default=False,
        help="Clear carrier content for indirect attacks, making context empty (similar to no-context tasks 21-34)",
    )
    parser.add_argument(
        "--docker",
        action="store_true",
        help="Run OpenClaw agent inside a Docker container for isolation",
    )
    return parser.parse_args()


def _parse_task_range(range_str: str) -> List[str]:
    """Parse a task range string like '30-35' or 'task30-35' into a list of task IDs.

    Supported formats:
    - '30-35' -> ['task_30', 'task_31', ..., 'task_35']
    - 'task30-35' -> ['task_30', 'task_31', ..., 'task_35']
    - 'task_30-35' -> ['task_30', 'task_31', ..., 'task_35']
    """
    range_str = range_str.strip()

    # Extract start and end numbers from range
    # Match patterns like: 30-35, task30-35, task_30-35
    match = re.match(r'^(?:task_?)?(\d+)-(\d+)$', range_str, re.IGNORECASE)
    if not match:
        return []  # Not a valid range format

    start, end = int(match.group(1)), int(match.group(2))
    if start > end:
        start, end = end, start

    return [f"task_{i}" for i in range(start, end + 1)]


def _select_task_ids(tasks: List[Task], suite: str) -> Optional[List[str]]:
    if suite == "all":
        return None
    if suite == "automated-only":
        return [task.task_id for task in tasks if task.grading_type == "automated"]
    if suite == "direct":
        # Return tasks from tasks/direct/ subdirectory
        return [
            task.task_id
            for task in tasks
            if task.file_path and "direct" in task.file_path.parts
        ]
    if suite == "indirect":
        # Return tasks from tasks/indirect/ subdirectory
        return [
            task.task_id
            for task in tasks
            if task.file_path and "indirect" in task.file_path.parts
        ]
    if suite == "non-security":
        # Return tasks from tasks/ root directory (not in direct/, indirect/, fptest/, or memory/)
        return [
            task.task_id
            for task in tasks
            if task.file_path
            and "direct" not in task.file_path.parts
            and "indirect" not in task.file_path.parts
            and "fptest" not in task.file_path.parts
            and "memory" not in task.file_path.parts
        ]
    if suite == "fptest":
        # Return tasks from tasks/fptest/ subdirectory
        return [
            task.task_id
            for task in tasks
            if task.file_path and "fptest" in task.file_path.parts
        ]
    if suite == "memory":
        # Return tasks from tasks/memory/ subdirectory
        return [
            task.task_id
            for task in tasks
            if task.file_path and "memory" in task.file_path.parts
        ]
    if suite == "chain":
        # Return tasks from tasks/chain/ subdirectory
        return [
            task.task_id
            for task in tasks
            if task.file_path and "chain" in task.file_path.parts
        ]
    if suite == "skills_poison_EN":
        # Return tasks from tasks/skills_poison_EN/ subdirectory
        return [
            task.task_id
            for task in tasks
            if task.file_path and "skills_poison_EN" in task.file_path.parts
        ]

    # Parse comma-separated items, supporting ranges like "task30-35" or "30-35"
    task_ids = []
    for item in suite.split(","):
        item = item.strip()
        if not item:
            continue

        # Try to parse as a range first
        range_ids = _parse_task_range(item)
        if range_ids:
            task_ids.extend(range_ids)
        else:
            # Single task ID - normalize to task_N format if needed
            # Support: task_30, task30, 30 -> all become task_30
            match = re.match(r'^(?:task_?)?(\d+)$', item, re.IGNORECASE)
            if match:
                task_ids.append(f"task_{match.group(1)}")
            else:
                task_ids.append(item)

    return task_ids


def _next_run_id(run_root: Path) -> str:
    run_root.mkdir(parents=True, exist_ok=True)
    existing = []
    for entry in run_root.iterdir():
        if entry.is_dir() and entry.name.isdigit():
            existing.append(int(entry.name))
    next_id = (max(existing) + 1) if existing else 1
    return f"{next_id:04d}"


def _get_git_version(script_dir: Path) -> str:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            capture_output=True,
            text=True,
            timeout=2,
            check=False,
            cwd=script_dir,
        )
    except (subprocess.SubprocessError, FileNotFoundError, OSError):
        return ""
    if result.returncode != 0:
        return ""
    return result.stdout.strip()


def _compute_efficiency_summary(
    task_entries: List[Dict[str, Any]],
    grades_by_task_id: Dict[str, Dict[str, Any]],
) -> Dict[str, Any]:
    """Compute aggregate token efficiency metrics across all tasks.

    Returns a dict with total token usage, cost, and efficiency ratios
    (score per token, score per dollar) so that different models can be
    compared not just on quality but also on resource consumption.
    """
    total_input_tokens = 0
    total_output_tokens = 0
    total_tokens = 0
    total_cost_usd = 0.0
    total_requests = 0
    total_execution_time = 0.0
    tasks_with_usage = 0

    per_task_efficiency: List[Dict[str, Any]] = []
    for entry in task_entries:
        usage = entry.get("usage", {})
        task_id = entry["task_id"]
        grading = grades_by_task_id.get(task_id, {})
        score = float(grading.get("mean", 0.0))

        inp = int(usage.get("input_tokens", 0))
        out = int(usage.get("output_tokens", 0))
        tot = int(usage.get("total_tokens", 0))
        cost = float(usage.get("cost_usd", 0.0) or 0.0)
        reqs = int(usage.get("request_count", 0))
        exec_time = float(entry.get("execution_time", 0.0) or 0.0)

        total_input_tokens += inp
        total_output_tokens += out
        total_tokens += tot
        total_cost_usd += cost
        total_requests += reqs
        total_execution_time += exec_time

        if tot > 0:
            tasks_with_usage += 1

        per_task_efficiency.append(
            {
                "task_id": task_id,
                "score": round(score, 4),
                "total_tokens": tot,
                "cost_usd": round(cost, 6),
                "tokens_per_score_point": round(tot / score, 1) if score > 0 else None,
            }
        )

    # Aggregate scores
    all_scores = [float(g.get("mean", 0.0)) for g in grades_by_task_id.values()]
    total_score = sum(all_scores)
    num_tasks = len(all_scores)

    summary: Dict[str, Any] = {
        "total_tokens": total_tokens,
        "total_input_tokens": total_input_tokens,
        "total_output_tokens": total_output_tokens,
        "total_cost_usd": round(total_cost_usd, 6),
        "total_requests": total_requests,
        "total_execution_time_seconds": round(total_execution_time, 2),
        "tasks_with_usage_data": tasks_with_usage,
        "tokens_per_task": round(total_tokens / num_tasks, 1) if num_tasks > 0 else 0,
        "cost_per_task_usd": round(total_cost_usd / num_tasks, 6) if num_tasks > 0 else 0,
        "score_per_1k_tokens": (
            round(total_score / (total_tokens / 1000), 6) if total_tokens > 0 else None
        ),
        "score_per_dollar": (
            round(total_score / total_cost_usd, 4) if total_cost_usd > 0 else None
        ),
        "per_task": per_task_efficiency,
    }
    return summary


def _log_efficiency_summary(
    efficiency: Dict[str, Any],
    grades_by_task_id: Dict[str, Dict[str, Any]],
) -> None:
    """Log a human-readable token efficiency summary."""
    all_scores = [float(g.get("mean", 0.0)) for g in grades_by_task_id.values()]
    mean_score = statistics.mean(all_scores) if all_scores else 0.0

    logger.info("\n%s", "=" * 80)
    logger.info("📊 TOKEN EFFICIENCY SUMMARY")
    logger.info("%s", "=" * 80)
    logger.info(
        "   Total tokens used: %s (input: %s, output: %s)",
        f"{efficiency['total_tokens']:,}",
        f"{efficiency['total_input_tokens']:,}",
        f"{efficiency['total_output_tokens']:,}",
    )
    logger.info("   Total API requests: %s", f"{efficiency['total_requests']:,}")
    if efficiency["total_cost_usd"] > 0:
        logger.info("   Total cost: $%.4f", efficiency["total_cost_usd"])
    logger.info(
        "   Avg tokens/task: %s",
        f"{efficiency['tokens_per_task']:,.0f}",
    )
    logger.info("   Mean score: %.4f", mean_score)
    if efficiency.get("score_per_1k_tokens") is not None:
        logger.info(
            "   Score per 1K tokens: %.4f (higher = more efficient)",
            efficiency["score_per_1k_tokens"],
        )
    if efficiency.get("score_per_dollar") is not None:
        logger.info(
            "   Score per dollar: %.4f (higher = more cost-efficient)",
            efficiency["score_per_dollar"],
        )
    logger.info("%s", "=" * 80)


def _output_single_task(
    output_dir: Path,
    run_id: str,
    model_slug: str,
    result: Dict[str, Any],
    grade: GradeResult,
    task: Task,
    runs_per_task: int = 1,
    run_index: int = 0,
) -> None:
    """Immediately output a single task's result to job/{task_id}/task.json or job/{task_id}/task_run_{N}.json"""
    # Extract base run_id (remove -N suffix if present)
    base_run_id = run_id
    if '-' in run_id:
        parts = run_id.rsplit('-', 1)
        if parts[-1].isdigit():
            base_run_id = parts[0]

    job_dir = output_dir / f"job_{base_run_id}"
    job_dir.mkdir(parents=True, exist_ok=True)

    task_id = result["task_id"]
    task_dir = job_dir / f"task_{task_id}"
    task_dir.mkdir(parents=True, exist_ok=True)

    # Build the complete structure for a single task
    grade_dict = grade.to_dict()
    task_output = {
        "job_id": base_run_id,
        "run_index": run_index + 1,  # 1-based run number
        "runs_per_task": runs_per_task,
        "model": model_slug,
        "task_id": task_id,
        "status": result.get("status"),
        "timed_out": result.get("timed_out"),
        "execution_time": result.get("execution_time"),
        "transcript": result.get("transcript", []),
        "transcript_length": len(result.get("transcript", [])),
        "transcript_summary": grade_dict.pop("transcript_summary", ""),  # Extract to top level
        "usage": result.get("usage", {}),
        "workspace": result.get("workspace"),
        "grading": grade_dict,
        "frontmatter": task.frontmatter,
        # Include execution details
        "exit_code": result.get("exit_code"),
        "stdout": result.get("stdout", ""),
        "stderr": result.get("stderr", ""),
    }

    # Save file: use task_{task_id}.json for run=1 and task_{task_id}_run_{N}.json for run>1
    if runs_per_task > 1:
        task_file = task_dir / f"task_{task_id}_run_{run_index + 1}.json"
    else:
        task_file = task_dir / f"task_{task_id}.json"
    task_file.write_text(json.dumps(task_output, indent=2, ensure_ascii=False), encoding="utf-8")
    logger.info("Saved task result: %s", task_file)

def _log_category_summary(
    task_entries: List[Dict[str, Any]],
    tasks_by_id: Dict[str, Any],
) -> None:
    """Log a summary grouped by category, matching the AgentScry website format."""
    # Group scores by category
    category_scores: Dict[str, Dict[str, float]] = {}

    for entry in task_entries:
        task_id = entry["task_id"]
        task = tasks_by_id.get(task_id)
        if not task:
            continue

        category = task.category.upper() if task.category else "UNCATEGORIZED"
        grading = entry.get("grading", {})
        mean_score = float(grading.get("mean", 0.0))
        max_score = 1.0  # Each task is scored 0-1

        if category not in category_scores:
            category_scores[category] = {"earned": 0.0, "possible": 0.0, "task_count": 0}

        category_scores[category]["earned"] += mean_score
        category_scores[category]["possible"] += max_score
        category_scores[category]["task_count"] += 1

    # Calculate overall totals
    total_earned = sum(c["earned"] for c in category_scores.values())
    total_possible = sum(c["possible"] for c in category_scores.values())
    overall_pct = (total_earned / total_possible * 100) if total_possible > 0 else 0

    logger.info("\n%s", "=" * 80)
    logger.info("🦀 SCRY SCORE SUMMARY")
    logger.info("%s", "=" * 80)
    logger.info("")
    logger.info("   Overall Score: %.1f%% (%.1f / %.1f)", overall_pct, total_earned, total_possible)
    logger.info("")
    logger.info("   %-20s %8s %12s", "CATEGORY", "SCORE", "TASKS")
    logger.info("   %s", "-" * 44)

    # Sort categories alphabetically for consistent output
    for category in sorted(category_scores.keys()):
        data = category_scores[category]
        pct = (data["earned"] / data["possible"] * 100) if data["possible"] > 0 else 0
        task_count = int(data["task_count"])
        task_label = "task" if task_count == 1 else "tasks"

        # Color indicator based on score
        if pct >= 90:
            indicator = "🟢"
        elif pct >= 70:
            indicator = "🟡"
        else:
            indicator = "🔴"

        logger.info(
            "   %s %-17s %6.1f%% %6d %s",
            indicator,
            category,
            pct,
            task_count,
            task_label,
        )

    logger.info("   %s", "-" * 44)
    logger.info("%s", "=" * 80)


def main():
    """Main entry point for the benchmark script."""
    # Determine tasks directory
    script_dir = Path(__file__).parent
    skill_root = script_dir.parent  # Parent of scripts/ is the skill root
    tasks_dir = skill_root / "tasks"

    logger.info("AgentScry - OpenClaw Benchmarking")
    logger.info("Starting AgentScry")
    time.sleep(5)

    if not tasks_dir.exists():
        logger.error(f"❌ Tasks directory not found: {tasks_dir}")
        sys.exit(1)

    args = _parse_args()
    if not args.model:
        logger.error("Missing required argument: --model")
        sys.exit(2)

    logger.info("🔧 Initializing BenchmarkRunner...")
    runner = BenchmarkRunner(tasks_dir)

    logger.info("📂 Loading tasks from directory...")
    runner.load_tasks(verbose=args.verbose)

    model_slug = slugify_model(args.model)
    # Format: {suite}#{model}#{attack}#{timestamp}, e.g. indirect#GLM-5#important_message#20260413_173400
    suite_slug = args.suite.replace(",", "_").replace(" ", "_")
    attack_slug = args.attack.replace(":", "_").replace(" ", "_") if args.attack else "no-attack"
    from datetime import datetime
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    context_slug = "no_context" if args.no_context else "with_context"
    run_semantic_id = f"{suite_slug}#{model_slug}#{attack_slug}#{context_slug}#{timestamp}"
    # Define output_dir early so each task can write JSON immediately after completion
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    # Current project directory
    skill_dir = skill_root
    # agent_id naming
    agent_id = f"bench-{model_slug}"
    # Path accessible to the task itself
    task_root = Path("/tmp/scry")
    # Use a UUID for the workspace to avoid overly long paths or special characters
    run_id = uuid.uuid4().hex
    # Single-task workspace, e.g. '/tmp/scry/6cc7062673d04682ae0392161f11ab72'
    task_agent_workspace_root = Path(f"{task_root}/{run_id}")
    # Agent workspace, e.g. '/tmp/scry/6cc7062673d04682ae0392161f11ab72/agent_workspace'
    task_agent_workspace_root_relate = Path(f"{task_agent_workspace_root}/agent_workspace")
    # Local agent workspace, e.g. '/tmp/scry/6cc7062673d04682ae0392161f11ab72/tmp/scry/6cc7062673d04682ae0392161f11ab72/agent_workspace'
    local_task_agent_workspace_root_relate = Path(f"{task_agent_workspace_root}/{task_agent_workspace_root_relate}")

    if not args.docker:
        ensure_agent_exists(agent_id, args.model, local_task_agent_workspace_root_relate)
        cleanup_agent_sessions(agent_id)

    task_ids = _select_task_ids(runner.tasks, args.suite)
    results = []
    grades_by_task_id = {}
    sanity_task_id = "task_00_sanity"

    tasks_to_run = runner.tasks
    if task_ids is not None:
        # Match by prefix: task_31 matches task_31_xxx, task_31 matches task_31
        def matches_task(task_id: str, patterns: List[str]) -> bool:
            for pattern in patterns:
                if task_id == pattern:
                    return True
                # task_31 should match task_31_xxx (prefix match with underscore)
                if task_id.startswith(pattern + "_"):
                    return True
            return False

        tasks_to_run = [task for task in runner.tasks if matches_task(task.task_id, task_ids)]
    tasks_by_id = {task.task_id: task for task in tasks_to_run}

    # Validate attack compatibility with tasks
    if args.attack:
        attack = get_attack_method(args.attack)
        for task in tasks_to_run:
            task_category = task.frontmatter.get("attack_category")
            if task_category is None:
                # Indirect tasks don't have attack_category;
                # allow indirect attacks on them, warn for other categories
                if attack.category == "indirect":
                    continue
                logger.warning(
                    "⚠️ Task '%s' has no attack_category field; --attack will be ignored for this task",
                    task.task_id,
                )
                continue
            try:
                validate_attack_compatibility(args.attack, task_category)
            except ValueError as exc:
                logger.error("❌ Attack compatibility error: %s", exc)
                logger.error("   Task '%s' has attack_category='%s'", task.task_id, task_category)
                sys.exit(1)
        logger.info("🔓 Attack method: %s (category: %s)", args.attack, attack.category)

    runs_per_task = max(1, args.runs)
    for i, task in enumerate(tasks_to_run, 1):
        task_grades = []
        for run_index in range(runs_per_task):
            logger.info("\n%s", "=" * 80)
            logger.info(
                "📋 Task %s/%s (Run %s/%s)",
                i,
                len(tasks_to_run),
                run_index + 1,
                runs_per_task,
            )
            logger.info("%s", "=" * 80)
            execution_error = None
            tracee_log = None  # Initialize here to avoid UnboundLocalError
            try:
                if args.docker:
                    docker.start()
                    ensure_agent_exists(agent_id, args.model, task_agent_workspace_root_relate)

                try:
                    result = execute_openclaw_task(
                        task=task,
                        agent_id=agent_id,
                        model_id=args.model,
                        run_id=f"{run_id}-{run_index + 1}",
                        timeout_multiplier=args.timeout_multiplier,
                        skill_dir=skill_dir, # Current project directory
                        task_agent_workspace_root=task_agent_workspace_root, # Local unique workspace bound to this task: /tmp/scry/{run_id}
                        task_agent_workspace_root_relate = task_agent_workspace_root_relate,
                        local_task_agent_workspace_root_relate=local_task_agent_workspace_root_relate,
                        verbose=args.verbose,
                        attack_method=args.attack,
                        no_context=args.no_context,
                    )


                except Exception as exc:
                    execution_error = str(exc)
                    import traceback
                    logger.warning("Task execution failed for %s, continuing: %s\n%s", task.task_id, exc, traceback.format_exc())
                    result = {
                        "agent_id": agent_id,
                        "task_id": task.task_id,
                        "status": "error",
                        "transcript": [],
                        "usage": {},
                        "workspace": "",
                        "exit_code": -1,
                        "timed_out": False,
                        "execution_time": 0.0,
                        "stdout": "",
                        "stderr": execution_error,
                    }

                if docker.is_active():
                    # Stop container before grading — judge runs on host, not in Docker
                    # (transcript already copied inside execute_openclaw_task)
                    docker.stop()

                try:
                    grade_kwargs = dict(
                        task=task, execution_result=result, skill_dir=skill_dir, verbose=args.verbose
                    )
                    if args.judge:
                        grade_kwargs["judge_model"] = args.judge
                    grade = grade_task(**grade_kwargs)
                except Exception as exc:
                    if execution_error:
                        note = f"Execution failed: {execution_error}; Grading failed: {exc}"
                    else:
                        note = f"Grading failed: {exc}"
                    logger.warning("Task grading failed for %s, continuing: %s", task.task_id, exc)
                    logger.warning("Full traceback:\n%s", traceback.format_exc())
                    grade = GradeResult(
                        task_id=task.task_id,
                        score=0.0,
                        max_score=1.0,
                        grading_type=task.grading_type,
                        breakdown={},
                        notes=note,
                    )
            finally:
                if docker.is_active():
                    docker.stop()
            task_grades.append(grade)
            results.append(result)

            # Immediately output this task's result to json
            # Use correct run_id (with run_index suffix if runs_per_task > 1)
            current_run_semantic_id = f"{run_semantic_id}-{run_index + 1}" if runs_per_task > 1 else run_semantic_id
            _output_single_task(output_dir, current_run_semantic_id, model_slug, result, grade, task, runs_per_task, run_index)

            # Log score immediately after grading
            score_pct = grade.score / grade.max_score * 100 if grade.max_score > 0 else 0
            status_emoji = (
                "✅" if grade.score >= grade.max_score else "⚠️" if grade.score > 0 else "❌"
            )
            logger.info(
                "%s Task %s: %.1f/%.1f (%.0f%%) - %s",
                status_emoji,
                task.task_id,
                grade.score,
                grade.max_score,
                score_pct,
                grade.grading_type,
            )
            if grade.notes:
                logger.info("   Notes: %s", grade.notes)

        task_scores = [grade.score for grade in task_grades]
        grades_by_task_id[task.task_id] = {
            "runs": [grade.to_dict() for grade in task_grades],
            "mean": statistics.mean(task_scores),
            "std": statistics.stdev(task_scores) if len(task_scores) > 1 else 0.0,
            "min": min(task_scores),
            "max": max(task_scores),
        }

        if (
            task.task_id == sanity_task_id
            and grades_by_task_id[task.task_id]["mean"] == 0.0
            and not args.no_fail_fast
        ):
            logger.error(
                "🚨 FAIL FAST: Sanity check (%s) scored 0%%. Aborting benchmark run to avoid wasting resources.",
                sanity_task_id,
            )
            sys.exit(3)

    # output_dir is already defined above
    # output_dir = Path(args.output_dir)
    # output_dir.mkdir(parents=True, exist_ok=True)

    task_entries = [
        {
            "task_id": result["task_id"],
            "status": result["status"],
            "timed_out": result["timed_out"],
            "execution_time": result["execution_time"],
            "transcript": result.get("transcript", []),
            "transcript_length": len(result["transcript"]),
            "usage": result.get("usage", {}),
            "workspace": result["workspace"],
            "grading": grades_by_task_id[result["task_id"]],
            "frontmatter": tasks_by_id[result["task_id"]].frontmatter,
            # Include execution details
            "exit_code": result.get("exit_code"),
            "stdout": result.get("stdout", ""),
            "stderr": result.get("stderr", ""),
        }
        for result in results
    ]

    efficiency = _compute_efficiency_summary(task_entries, grades_by_task_id)

    aggregate = {
        "model": args.model,
        "benchmark_version": _get_git_version(skill_root),
        "run_id": run_id,
        "timestamp": time.time(),
        "suite": args.suite,
        "attack_method": args.attack,
        "no_context": args.no_context,
        "runs_per_task": runs_per_task,
        "tasks": task_entries,
        "efficiency": efficiency,
    }

    output_path = output_dir / f"{run_semantic_id}_{model_slug}.json"
    output_path.write_text(json.dumps(aggregate, indent=2), encoding="utf-8")

    # _output_single_task writes each task result as soon as it completes, so _output_structured_tasks is not needed here

    # Calculate and log final score summary
    total_score = sum(grades_by_task_id[tid]["mean"] for tid in grades_by_task_id)
    max_score = float(len(grades_by_task_id))  # Each task has max_score of 1.0
    score_pct = (total_score / max_score * 100) if max_score > 0 else 0
    logger.info("📊 Final score: %.2f/%.0f (%.1f%%)", total_score, max_score, score_pct)

    logger.info("Saved results to %s", output_path)
    _log_category_summary(task_entries, tasks_by_id)
    _log_efficiency_summary(efficiency, grades_by_task_id)


if __name__ == "__main__":
    main()
