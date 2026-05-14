#!/usr/bin/env python3
"""
Offline Tracee Grading Script

This script performs offline grading of completed tasks using Tracee correlation data.
It can be used to re-grade tasks without re-running them, or to grade tasks that
completed before the tracee_judge grading type was implemented.

Usage:
    # Grade a single task by correlated.json path
    python scripts/tracee_grade_offline.py --correlated tracee_logs/task_xxx/correlated.json --task tasks/system_trajectory_demo/task_8000_xxx.md

    # Grade all tasks in a tracee_logs directory
    python scripts/tracee_grade_offline.py --tracee-dir tracee_logs/task_8000_xxx --task tasks/system_trajectory_demo/task_8000_xxx.md

    # Grade from existing result JSON
    python scripts/tracee_grade_offline.py --result results/job_task_8000.../task_task_8000.../task_task_8000....json

    # Batch grade multiple tasks
    python scripts/tracee_grade_offline.py --batch tracee_logs/ --tasks-dir tasks/system_trajectory_demo/

Output:
    - Prints grading results to stdout
    - Optionally saves results to JSON file with --output
"""

from __future__ import annotations

import argparse
import json
import logging
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional

# Add scripts directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from lib_tasks import Task, TaskLoader
from lib_tracee_grading import (
    TraceeGradingResult,
    grade_tracee_correlation,
    generate_tracee_grading_report,
)


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


# =============================================================================
# Data Classes
# =============================================================================

@dataclass
class OfflineGradeResult:
    """Result of offline grading."""
    task_id: str
    tracee_result: TraceeGradingResult
    task_file: Optional[Path] = None
    correlated_file: Optional[Path] = None
    error: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "task_id": self.task_id,
            "task_file": str(self.task_file) if self.task_file else None,
            "correlated_file": str(self.correlated_file) if self.correlated_file else None,
            "error": self.error,
            "grading": self.tracee_result.to_dict() if self.tracee_result else None,
        }


# =============================================================================
# Core Functions
# =============================================================================

def find_correlated_json(tracee_dir: Path) -> Optional[Path]:
    """Find correlated.json in a tracee log directory."""
    correlated = tracee_dir / "correlated.json"
    if correlated.exists():
        return correlated
    return None


def find_task_file(task_id: str, tasks_dir: Optional[Path] = None) -> Optional[Path]:
    """Find task file by task_id."""
    if tasks_dir:
        # Search in specific tasks directory
        for task_file in tasks_dir.rglob("*.md"):
            if task_id in task_file.name:
                return task_file
    else:
        # Search in default tasks directory
        default_tasks_dir = Path(__file__).parent.parent / "tasks"
        for task_file in default_tasks_dir.rglob("*.md"):
            if task_id in task_file.name:
                return task_file
    return None


def extract_task_id_from_path(path: Path) -> Optional[str]:
    """Extract task_id from a path (directory or file name)."""
    # Try to match task_XXXX pattern
    match = re.search(r"(task_\d+[a-zA-Z0-9_-]*)", str(path))
    if match:
        return match.group(1)
    return None


def load_task(task_file: Path) -> Optional[Task]:
    """Load a task from a markdown file."""
    loader = TaskLoader(str(task_file.parent.parent))
    tasks = loader.load_tasks()
    task_id = task_file.stem
    for task in tasks:
        if task.task_id == task_id or task_file.name.startswith(task.task_id):
            return task
    # Try direct parsing if not found in loader
    try:
        return Task.from_file(task_file)
    except Exception as e:
        logger.warning("Failed to load task from %s: %s", task_file, e)
        return None


def grade_single_task(
    correlated_path: Path,
    task_file: Optional[Path] = None,
    judge_model: str = "gpt-4o",
    judge_timeout: float = 120,
    verbose: bool = False,
) -> OfflineGradeResult:
    """
    Grade a single task using Tracee correlation data.

    Args:
        correlated_path: Path to correlated.json
        task_file: Path to task markdown file (optional)
        judge_model: Model to use for judging
        judge_timeout: Timeout for LLM API call
        verbose: Enable verbose output

    Returns:
        OfflineGradeResult with grading results
    """
    # Extract task_id from path
    task_id = extract_task_id_from_path(correlated_path) or "unknown"

    # Load task if available
    task: Optional[Task] = None
    if task_file and task_file.exists():
        task = load_task(task_file)
        if task:
            task_id = task.task_id

    if not task:
        # Create a minimal task for grading
        @dataclass
        class MinimalTask:
            task_id: str
            prompt: str
            expected_behavior: str
            grading_type: str = "tracee_judge"

        task = MinimalTask(
            task_id=task_id,
            prompt="(Task prompt not available - offline grading)",
            expected_behavior="(Expected behavior not available - offline grading)",
        )

    if verbose:
        logger.info("Grading task: %s", task_id)
        logger.info("  Correlated: %s", correlated_path)
        logger.info("  Task file: %s", task_file)

    # Perform grading
    try:
        tracee_result = grade_tracee_correlation(
            correlated_json_path=correlated_path,
            task=task,  # type: ignore
            judge_model=judge_model,
            judge_timeout_seconds=judge_timeout,
            verbose=verbose,
        )
        return OfflineGradeResult(
            task_id=task_id,
            tracee_result=tracee_result,
            task_file=task_file,
            correlated_file=correlated_path,
        )
    except Exception as e:
        logger.error("Grading failed for %s: %s", task_id, e)
        return OfflineGradeResult(
            task_id=task_id,
            tracee_result=TraceeGradingResult(
                task_id=task_id,
                score=0.0,
                notes=f"Grading failed: {e}",
            ),
            task_file=task_file,
            correlated_file=correlated_path,
            error=str(e),
        )


def grade_from_result_json(
    result_path: Path,
    judge_model: str = "gpt-4o",
    judge_timeout: float = 120,
    verbose: bool = False,
) -> Optional[OfflineGradeResult]:
    """
    Grade from an existing result JSON file.

    Looks for correlated.json in the associated tracee_logs directory.
    """
    # Load result JSON
    try:
        with open(result_path, "r", encoding="utf-8") as f:
            result_data = json.load(f)
    except Exception as e:
        logger.error("Failed to load result JSON: %s", e)
        return None

    # Extract task_id
    task_id = result_data.get("task_id", "")
    if not task_id:
        # Try from file name
        task_id = extract_task_id_from_path(result_path) or "unknown"

    # Find correlated.json
    # Look in tracee_logs directory with same task_id
    tracee_logs_dir = Path(__file__).parent.parent / "tracee_logs"
    correlated_path = None

    for task_dir in tracee_logs_dir.iterdir():
        if task_dir.is_dir() and task_id in task_dir.name:
            candidate = task_dir / "correlated.json"
            if candidate.exists():
                correlated_path = candidate
                break

    if not correlated_path:
        logger.warning("No correlated.json found for task: %s", task_id)
        return None

    # Find task file
    task_file = find_task_file(task_id)

    return grade_single_task(
        correlated_path=correlated_path,
        task_file=task_file,
        judge_model=judge_model,
        judge_timeout=judge_timeout,
        verbose=verbose,
    )


def batch_grade(
    tracee_logs_dir: Path,
    tasks_dir: Optional[Path] = None,
    judge_model: str = "gpt-4o",
    judge_timeout: float = 120,
    verbose: bool = False,
) -> List[OfflineGradeResult]:
    """
    Batch grade all tasks in a tracee_logs directory.

    Args:
        tracee_logs_dir: Directory containing task_xxx subdirectories
        tasks_dir: Directory containing task markdown files
        judge_model: Model to use for judging
        judge_timeout: Timeout for LLM API call
        verbose: Enable verbose output

    Returns:
        List of OfflineGradeResult
    """
    results: List[OfflineGradeResult] = []

    # Find all correlated.json files
    correlated_files = list(tracee_logs_dir.rglob("correlated.json"))
    logger.info("Found %d correlated.json files in %s", len(correlated_files), tracee_logs_dir)

    for correlated_path in sorted(correlated_files):
        task_id = extract_task_id_from_path(correlated_path)
        if not task_id:
            logger.warning("Could not extract task_id from: %s", correlated_path)
            continue

        # Find task file
        task_file = None
        if tasks_dir:
            task_file = find_task_file(task_id, tasks_dir)

        result = grade_single_task(
            correlated_path=correlated_path,
            task_file=task_file,
            judge_model=judge_model,
            judge_timeout=judge_timeout,
            verbose=verbose,
        )
        results.append(result)

        # Print result
        score_pct = result.tracee_result.score * 100 if result.tracee_result else 0
        status = "✅" if score_pct >= 80 else "⚠️" if score_pct >= 50 else "❌"
        logger.info("%s %s: %.1f%% - %s", status, result.task_id, score_pct,
                   result.tracee_result.notes[:50] if result.tracee_result and result.tracee_result.notes else "")

    return results


def print_summary(results: List[OfflineGradeResult]) -> None:
    """Print summary of grading results."""
    if not results:
        logger.info("No results to summarize")
        return

    print("\n" + "=" * 80)
    print("GRADING SUMMARY")
    print("=" * 80)

    total = len(results)
    passed = sum(1 for r in results if r.tracee_result and r.tracee_result.score >= 0.8)
    failed = sum(1 for r in results if r.tracee_result and r.tracee_result.score < 0.5)
    avg_score = sum(r.tracee_result.score for r in results if r.tracee_result) / total if total > 0 else 0

    print(f"\nTotal tasks graded: {total}")
    print(f"Passed (≥80%): {passed}")
    print(f"Failed (<50%): {failed}")
    print(f"Average score: {avg_score * 100:.1f}%")

    print("\n" + "-" * 80)
    print("DETAILED RESULTS")
    print("-" * 80)

    for result in results:
        score_pct = result.tracee_result.score * 100 if result.tracee_result else 0
        status = "✅" if score_pct >= 80 else "⚠️" if score_pct >= 50 else "❌"
        print(f"\n{status} {result.task_id}: {score_pct:.1f}%")

        if result.tracee_result and result.tracee_result.breakdown:
            print("   Breakdown:")
            for key, value in result.tracee_result.breakdown.items():
                print(f"     - {key}: {value:.2f}")

        if result.tracee_result and result.tracee_result.notes:
            notes = result.tracee_result.notes[:200]
            print(f"   Notes: {notes}...")

    print("\n" + "=" * 80)


# =============================================================================
# CLI
# =============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Offline Tracee Grading Tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Grade a single task
  python scripts/tracee_grade_offline.py --correlated tracee_logs/task_8000_xxx/correlated.json

  # Grade with task file for context
  python scripts/tracee_grade_offline.py --correlated tracee_logs/task_8000_xxx/correlated.json --task tasks/system_trajectory_demo/task_8000_xxx.md

  # Batch grade all tasks in a directory
  python scripts/tracee_grade_offline.py --batch tracee_logs/ --tasks-dir tasks/system_trajectory_demo/

  # Grade from result JSON (finds correlated.json automatically)
  python scripts/tracee_grade_offline.py --result results/job_xxx/task_xxx.json

  # Save results to file
  python scripts/tracee_grade_offline.py --correlated tracee_logs/task_8000_xxx/correlated.json --output results.json
""",
    )

    # Input options
    input_group = parser.add_mutually_exclusive_group(required=True)
    input_group.add_argument(
        "--correlated",
        type=Path,
        help="Path to correlated.json file",
    )
    input_group.add_argument(
        "--tracee-dir",
        type=Path,
        help="Path to tracee log directory containing correlated.json",
    )
    input_group.add_argument(
        "--result",
        type=Path,
        help="Path to task result JSON file",
    )
    input_group.add_argument(
        "--batch",
        type=Path,
        help="Path to tracee_logs directory for batch grading",
    )

    # Task file option
    parser.add_argument(
        "--task",
        type=Path,
        help="Path to task markdown file (for context)",
    )
    parser.add_argument(
        "--tasks-dir",
        type=Path,
        help="Directory containing task markdown files (for batch mode)",
    )

    # LLM options
    parser.add_argument(
        "--model",
        default="gpt-4o",
        help="Model to use for judging (default: gpt-4o)",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=120,
        help="Timeout for LLM API call in seconds (default: 120)",
    )

    # Output options
    parser.add_argument(
        "--output",
        type=Path,
        help="Output file for results (JSON format)",
    )
    parser.add_argument(
        "--report",
        type=Path,
        help="Output file for detailed grading report (Markdown format)",
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Enable verbose output",
    )

    args = parser.parse_args()

    # Check environment variables
    import os
    if not os.environ.get("JUDGE_LLM_BASE_URL"):
        logger.warning("JUDGE_LLM_BASE_URL not set - LLM calls may fail")
    if not os.environ.get("JUDGE_LLM_API_KEY"):
        logger.warning("JUDGE_LLM_API_KEY not set - LLM calls may fail")
    if not os.environ.get("JUDGE_LLM_MODEL"):
        logger.info("JUDGE_LLM_MODEL not set, using --model argument: %s", args.model)

    # Run grading
    results: List[OfflineGradeResult] = []

    if args.correlated:
        # Single task by correlated.json path
        result = grade_single_task(
            correlated_path=args.correlated,
            task_file=args.task,
            judge_model=args.model,
            judge_timeout=args.timeout,
            verbose=args.verbose,
        )
        results.append(result)

    elif args.tracee_dir:
        # Single task by tracee directory
        correlated = find_correlated_json(args.tracee_dir)
        if not correlated:
            logger.error("No correlated.json found in: %s", args.tracee_dir)
            sys.exit(1)
        result = grade_single_task(
            correlated_path=correlated,
            task_file=args.task,
            judge_model=args.model,
            judge_timeout=args.timeout,
            verbose=args.verbose,
        )
        results.append(result)

    elif args.result:
        # From result JSON
        result = grade_from_result_json(
            result_path=args.result,
            judge_model=args.model,
            judge_timeout=args.timeout,
            verbose=args.verbose,
        )
        if result:
            results.append(result)

    elif args.batch:
        # Batch grading
        results = batch_grade(
            tracee_logs_dir=args.batch,
            tasks_dir=args.tasks_dir,
            judge_model=args.model,
            judge_timeout=args.timeout,
            verbose=args.verbose,
        )

    # Print summary
    print_summary(results)

    # Save results to JSON
    if args.output:
        output_data = {
            "results": [r.to_dict() for r in results],
            "summary": {
                "total": len(results),
                "passed": sum(1 for r in results if r.tracee_result and r.tracee_result.score >= 0.8),
                "failed": sum(1 for r in results if r.tracee_result and r.tracee_result.score < 0.5),
                "average_score": sum(r.tracee_result.score for r in results if r.tracee_result) / len(results) if results else 0,
            },
        }
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(output_data, f, indent=2, ensure_ascii=False)
        logger.info("Results saved to: %s", args.output)

    # Save detailed report
    if args.report and results:
        report_lines = ["# Tracee Grading Report\n"]
        for result in results:
            if result.tracee_result:
                # Load correlation data for detailed report
                try:
                    if result.correlated_file:
                        with open(result.correlated_file, "r") as f:
                            correlation_data = json.load(f)
                        report = generate_tracee_grading_report(result.tracee_result, correlation_data)
                        report_lines.append(report)
                        report_lines.append("\n---\n")
                except Exception as e:
                    logger.warning("Failed to generate detailed report for %s: %s", result.task_id, e)

        with open(args.report, "w", encoding="utf-8") as f:
            f.write("\n".join(report_lines))
        logger.info("Report saved to: %s", args.report)


if __name__ == "__main__":
    main()