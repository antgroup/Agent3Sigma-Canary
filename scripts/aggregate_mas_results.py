#!/usr/bin/env python3
"""
AgentScry MAS Results Aggregator

Aggregates experiment results from multiple benchmark runs, extracting MAS system
features, model information, and scoring data into training-friendly formats.

Usage:
    # Aggregate all results in results/ directory
    python scripts/aggregate_mas_results.py

    # Aggregate specific result directories
    python scripts/aggregate_mas_results.py results/0516_official_mas_*

    # Output as CSV (default: JSONL)
    python scripts/aggregate_mas_results.py --format csv

    # Filter by MAS system
    python scripts/aggregate_mas_results.py --mas mas_1_dev_team

    # Filter by model
    python scripts/aggregate_mas_results.py --model claude-sonnet-4

    # Include transcript summaries in output
    python scripts/aggregate_mas_results.py --include-summaries

Output formats:
    - JSONL: one record per task run, flat structure with nested MAS features
    - CSV:  flat table, one row per task run, MAS features as prefixed columns
    - JSON: nested structure grouped by (model, mas_system, attack_suite)

The script produces two files:
    1. {prefix}_records.{format}  — per-task records with full feature vectors
    2. {prefix}_summary.{format}  — aggregated summary by (model, mas_system, task_category)
"""

import argparse
import csv
import json
import logging
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

# Add project root to path
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
sys.path.insert(0, str(PROJECT_ROOT))

logger = logging.getLogger("aggregate_mas_results")


# ---------------------------------------------------------------------------
# Feature extraction
# ---------------------------------------------------------------------------

def extract_mas_features(mas_profile: Dict[str, Any]) -> Dict[str, Any]:
    """Extract structured MAS features from a mas_system_profile dict.

    Returns a flat dict with prefixed keys suitable for ML feature vectors.
    """
    features: Dict[str, Any] = {}

    if not mas_profile:
        return features

    # Basic system info
    features["mas_system_id"] = mas_profile.get("system_id", "")
    features["mas_system_name"] = mas_profile.get("system_name", "")
    features["mas_interaction_pattern"] = mas_profile.get("interaction_pattern", "")
    features["mas_communication_protocol"] = mas_profile.get("communication_protocol", "")
    features["mas_shared_workspace"] = mas_profile.get("shared_workspace", True)
    features["mas_max_rounds"] = mas_profile.get("max_rounds", 3)
    features["mas_role_count"] = mas_profile.get("role_count", 0)
    features["mas_user_entry_point"] = mas_profile.get("user_entry_point", "")

    # Topology features
    topology = mas_profile.get("topology", {})
    features["mas_topology_type"] = topology.get("type", "")
    features["mas_topology_edge_count"] = len(topology.get("edges", []))

    # Edge type distribution
    edge_types: Dict[str, int] = defaultdict(int)
    for edge in topology.get("edges", []):
        edge_types[edge.get("type", "unknown")] += 1
    features["mas_topology_edge_types"] = dict(edge_types)

    # Role-level features
    roles = mas_profile.get("roles", [])
    features["mas_roles"] = [
        {
            "role_id": r.get("role_id", ""),
            "name": r.get("name", ""),
            "is_target": r.get("is_target", False),
            "max_turns": r.get("max_turns", 1),
            "permission_count": sum(len(v) if isinstance(v, list) else 0
                                    for v in r.get("permissions", {}).values()),
        }
        for r in roles
    ]

    # Permission matrix summary
    perm_matrix = mas_profile.get("permission_matrix", {})
    total_permissions = 0
    for role_perms in perm_matrix.values():
        for perm_type, resources in role_perms.items():
            if isinstance(resources, list):
                total_permissions += len(resources)
    features["mas_total_permission_count"] = total_permissions
    features["mas_avg_permissions_per_role"] = (
        total_permissions / len(perm_matrix) if perm_matrix else 0
    )

    # Attack injection features
    attack = mas_profile.get("attack_injection", {})
    features["mas_attack_target_role"] = attack.get("target_role", "")
    features["mas_attack_injection_method"] = attack.get("injection_method", "")
    features["mas_attack_is_entry_point"] = attack.get("is_user_entry_point", False)

    # Workspace files
    ws_files = mas_profile.get("workspace_files", [])
    features["mas_workspace_file_count"] = len(ws_files)
    features["mas_workspace_files"] = ws_files

    return features


def extract_flat_mas_features(mas_profile: Dict[str, Any]) -> Dict[str, Any]:
    """Extract MAS features as a completely flat dict (no nested structures).

    Suitable for CSV output where each feature becomes a column.
    """
    features = extract_mas_features(mas_profile)

    # Flatten roles into count/flags
    roles = features.pop("mas_roles", [])
    features["mas_target_role_count"] = sum(1 for r in roles if r.get("is_target"))
    features["mas_max_turns_any_role"] = max((r.get("max_turns", 1) for r in roles), default=0)
    features["mas_avg_max_turns"] = (
        sum(r.get("max_turns", 1) for r in roles) / len(roles) if roles else 0
    )

    # Flatten edge types into individual counts
    edge_types = features.pop("mas_topology_edge_types", {})
    for etype, count in edge_types.items():
        features[f"mas_edge_type_{etype}"] = count

    # Flatten workspace files
    ws_files = features.pop("mas_workspace_files", [])
    features["mas_workspace_file_list"] = ";".join(
        f.get("path", f) if isinstance(f, dict) else f for f in ws_files
    )

    return features


def extract_model_info(model_str: str) -> Dict[str, str]:
    """Parse model string into provider and model name."""
    if "/" in model_str:
        provider, model_name = model_str.split("/", 1)
        return {"model_provider": provider, "model_name": model_name, "model_full": model_str}
    return {"model_provider": "unknown", "model_name": model_str, "model_full": model_str}


def extract_task_record(
    task_entry: Dict[str, Any],
    aggregate_meta: Dict[str, Any],
    include_summaries: bool = False,
) -> Optional[Dict[str, Any]]:
    """Extract a single task record from aggregate JSON task entry.

    Returns None if the task has no MAS data (skip non-MAS tasks in MAS mode).
    """
    mas_profile = task_entry.get("mas_system_profile")
    if not mas_profile:
        return None

    grading = task_entry.get("grading", {})
    frontmatter = task_entry.get("frontmatter", {})
    multi_agent = task_entry.get("multi_agent", {})

    # Model info
    model_info = extract_model_info(aggregate_meta.get("model", ""))

    # MAS features (flat for CSV compatibility)
    mas_features = extract_flat_mas_features(mas_profile)

    # Build record
    record: Dict[str, Any] = {
        # Run metadata
        "run_id": aggregate_meta.get("run_id", ""),
        "timestamp": aggregate_meta.get("timestamp", 0),
        "benchmark_version": aggregate_meta.get("benchmark_version", ""),
        "suite": aggregate_meta.get("suite", ""),
        "attack_method": aggregate_meta.get("attack_method") or "no_attack",
        "mas_system_arg": aggregate_meta.get("mas_system") or "",

        # Model info
        **model_info,

        # Task info
        "task_id": task_entry.get("task_id", ""),
        "task_category": frontmatter.get("category", ""),
        "task_name": frontmatter.get("name", ""),
        "attack_category": frontmatter.get("attack_category", ""),
        "original_intent": frontmatter.get("original_intent", ""),

        # Execution info
        "status": task_entry.get("status", ""),
        "timed_out": task_entry.get("timed_out", False),
        "execution_time": task_entry.get("execution_time", 0),

        # Scoring
        "score": grading.get("mean", 0),
        "score_std": grading.get("std", 0),
        "score_min": grading.get("min", 0),
        "score_max": grading.get("max", 0),
        "grading_type": grading.get("runs", [{}])[0].get("grading_type", "") if grading.get("runs") else "",
        "score_breakdown": grading.get("runs", [{}])[0].get("breakdown", {}) if grading.get("runs") else {},

        # Multi-agent session info
        "ma_interaction_pattern": multi_agent.get("interaction_pattern", ""),
        "ma_status": multi_agent.get("status", ""),
        "ma_total_execution_time": multi_agent.get("total_execution_time", 0),
        "ma_session_count": len(multi_agent.get("session_summaries", [])),

        # MAS features (flat)
        **mas_features,
    }

    # Per-role scores (if available from breakdown)
    session_summaries = multi_agent.get("session_summaries", [])
    for session in session_summaries:
        role_id = session.get("role_id", "unknown")
        record[f"ma_role_{role_id}_status"] = session.get("status", "")
        record[f"ma_role_{role_id}_execution_time"] = session.get("execution_time", 0)
        usage = session.get("usage", {})
        record[f"ma_role_{role_id}_total_tokens"] = usage.get("total_tokens", 0)
        record[f"ma_role_{role_id}_cost_usd"] = usage.get("cost_usd", 0)

    # Token usage
    usage = task_entry.get("usage", {})
    record["total_tokens"] = usage.get("total_tokens", 0)
    record["input_tokens"] = usage.get("input_tokens", 0)
    record["output_tokens"] = usage.get("output_tokens", 0)
    record["cost_usd"] = usage.get("cost_usd", 0)

    # Transcript summary (optional)
    if include_summaries:
        record["transcript_summary"] = task_entry.get("transcript_summary", "")
        record["transcript_length"] = task_entry.get("transcript_length", 0)

    # Compute derived features
    record["attack_success"] = 1.0 - record["score"]  # Higher score = safer, so ASR = 1 - score

    return record


# ---------------------------------------------------------------------------
# File discovery and loading
# ---------------------------------------------------------------------------

def discover_result_files(paths: List[Path]) -> List[Path]:
    """Discover aggregate JSON result files from given paths."""
    result_files = []
    for path in paths:
        if path.is_file() and path.suffix == ".json":
            result_files.append(path)
        elif path.is_dir():
            # Recursively find all aggregate JSON files
            for json_file in sorted(path.rglob("*.json")):
                # Skip task-level JSON files (they're in task_*/ subdirs)
                # We want aggregate files at the results/ level
                if "task_" not in json_file.parent.name:
                    result_files.append(json_file)
    return result_files


def load_aggregate_result(filepath: Path) -> Optional[Dict[str, Any]]:
    """Load an aggregate result JSON file."""
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            data = json.load(f)
        if "tasks" not in data:
            logger.warning("Skipping %s: no 'tasks' key (not an aggregate result)", filepath)
            return None
        return data
    except (json.JSONDecodeError, OSError) as e:
        logger.warning("Failed to load %s: %s", filepath, e)
        return None


# ---------------------------------------------------------------------------
# Aggregation
# ---------------------------------------------------------------------------

def aggregate_results(
    result_files: List[Path],
    mas_filter: Optional[str] = None,
    model_filter: Optional[str] = None,
    include_summaries: bool = False,
) -> Tuple[List[Dict[str, Any]], Dict[str, Any]]:
    """Aggregate results from multiple JSON files.

    Returns:
        (records, summary_stats) where:
        - records: list of per-task records with full feature vectors
        - summary_stats: aggregated statistics grouped by (model, mas_system, attack_suite)
    """
    all_records = []
    summary_groups: Dict[Tuple[str, str, str], List[Dict[str, Any]]] = defaultdict(list)

    for filepath in result_files:
        logger.info("Processing %s", filepath)
        data = load_aggregate_result(filepath)
        if not data:
            continue

        model = data.get("model", "unknown")
        mas_system = data.get("mas_system", "")

        # Apply filters
        if mas_filter and mas_filter != mas_system:
            continue
        if model_filter and model_filter not in model:
            continue

        # Extract metadata
        meta = {
            "model": model,
            "run_id": data.get("run_id", ""),
            "timestamp": data.get("timestamp", 0),
            "benchmark_version": data.get("benchmark_version", ""),
            "suite": data.get("suite", ""),
            "attack_method": data.get("attack_method"),
            "mas_system": mas_system,
            "no_context": data.get("no_context", False),
            "runs_per_task": data.get("runs_per_task", 1),
        }

        for task_entry in data.get("tasks", []):
            record = extract_task_record(task_entry, meta, include_summaries)
            if record is None:
                continue  # Skip non-MAS tasks

            all_records.append(record)

            # Group for summary
            group_key = (
                record.get("model_full", model),
                record.get("mas_system_id", mas_system),
                record.get("attack_category", record.get("attack_method", "unknown")),
            )
            summary_groups[group_key].append(record)

    # Compute summary statistics
    summary_stats = {}
    for (model, mas_sys, attack_cat), records in summary_groups.items():
        scores = [r["score"] for r in records]
        asrs = [r["attack_success"] for r in records]
        exec_times = [r["execution_time"] for r in records if r["execution_time"]]

        summary_key = f"{model}#{mas_sys}#{attack_cat}"
        summary_stats[summary_key] = {
            "model": model,
            "mas_system": mas_sys,
            "attack_category": attack_cat,
            "task_count": len(records),
            "score_mean": sum(scores) / len(scores) if scores else 0,
            "score_std": _std(scores),
            "score_min": min(scores) if scores else 0,
            "score_max": max(scores) if scores else 0,
            "asr_mean": sum(asrs) / len(asrs) if asrs else 0,  # Attack Success Rate
            "asr_std": _std(asrs),
            "execution_time_mean": sum(exec_times) / len(exec_times) if exec_times else 0,
            "tasks": [r["task_id"] for r in records],
        }

    return all_records, summary_stats


def _std(values: List[float]) -> float:
    """Compute standard deviation."""
    if len(values) < 2:
        return 0.0
    mean = sum(values) / len(values)
    variance = sum((v - mean) ** 2 for v in values) / (len(values) - 1)
    return variance ** 0.5


# ---------------------------------------------------------------------------
# Output writers
# ---------------------------------------------------------------------------

def write_jsonl(records: List[Dict[str, Any]], filepath: Path) -> None:
    """Write records as JSON Lines (one JSON object per line)."""
    with open(filepath, "w", encoding="utf-8") as f:
        for record in records:
            f.write(json.dumps(record, ensure_ascii=False, default=str) + "\n")
    logger.info("Wrote %d records to %s", len(records), filepath)


def write_csv(records: List[Dict[str, Any]], filepath: Path) -> None:
    """Write records as CSV with flattened nested structures."""
    if not records:
        logger.warning("No records to write to CSV")
        return

    # Flatten all records and collect all column names
    flat_records = []
    all_keys = set()
    for record in records:
        flat = _flatten_dict(record)
        flat_records.append(flat)
        all_keys.update(flat.keys())

    # Sort columns: important ones first, then alphabetical
    priority_cols = [
        "run_id", "model_full", "model_provider", "model_name",
        "mas_system_id", "mas_system_name", "mas_interaction_pattern",
        "mas_topology_type", "mas_role_count", "mas_user_entry_point",
        "task_id", "task_category", "attack_category", "attack_method",
        "mas_attack_injection_method", "mas_attack_target_role",
        "score", "attack_success", "grading_type",
        "status", "execution_time", "total_tokens", "cost_usd",
    ]
    other_cols = sorted(all_keys - set(priority_cols))
    fieldnames = [c for c in priority_cols if c in all_keys] + other_cols

    with open(filepath, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for flat in flat_records:
            writer.writerow(flat)

    logger.info("Wrote %d records to %s", len(records), filepath)


def write_json_summary(summary_stats: Dict[str, Any], filepath: Path) -> None:
    """Write summary statistics as JSON."""
    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(summary_stats, f, indent=2, ensure_ascii=False, default=str)
    logger.info("Wrote summary for %d groups to %s", len(summary_stats), filepath)


def write_csv_summary(summary_stats: Dict[str, Any], filepath: Path) -> None:
    """Write summary statistics as CSV."""
    if not summary_stats:
        logger.warning("No summary data to write")
        return

    fieldnames = [
        "model", "mas_system", "attack_category",
        "task_count", "score_mean", "score_std", "score_min", "score_max",
        "asr_mean", "asr_std", "execution_time_mean",
    ]

    with open(filepath, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for stats in summary_stats.values():
            writer.writerow(stats)

    logger.info("Wrote summary for %d groups to %s", len(summary_stats), filepath)


def _flatten_dict(d: Dict[str, Any], parent_key: str = "", sep: str = "_") -> Dict[str, Any]:
    """Flatten a nested dict into a single-level dict with prefixed keys."""
    items: List[Tuple[str, Any]] = []
    for k, v in d.items():
        new_key = f"{parent_key}{sep}{k}" if parent_key else k
        if isinstance(v, dict):
            items.extend(_flatten_dict(v, new_key, sep=sep).items())
        elif isinstance(v, list):
            # Convert lists to JSON strings for CSV compatibility
            items.append((new_key, json.dumps(v, ensure_ascii=False, default=str)))
        else:
            items.append((new_key, v))
    return dict(items)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Aggregate MAS experiment results into training-friendly formats",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Aggregate all results
  python scripts/aggregate_mas_results.py

  # Aggregate specific directories
  python scripts/aggregate_mas_results.py results/0516_*

  # Output as CSV
  python scripts/aggregate_mas_results.py --format csv

  # Filter by MAS system
  python scripts/aggregate_mas_results.py --mas mas_1_dev_team

  # Include transcript summaries
  python scripts/aggregate_mas_results.py --include-summaries
        """,
    )
    parser.add_argument(
        "paths",
        nargs="*",
        default=["results"],
        help="Paths to result files or directories (default: results/)",
    )
    parser.add_argument(
        "--format",
        choices=["jsonl", "csv", "both"],
        default="both",
        help="Output format (default: both)",
    )
    parser.add_argument(
        "--output-dir",
        default="aggregated",
        help="Output directory (default: aggregated/)",
    )
    parser.add_argument(
        "--prefix",
        default="",
        help="Output file prefix (default: mas_results_YYYYMMDD_HHMMSS)",
    )
    parser.add_argument(
        "--mas",
        default=None,
        help="Filter by MAS system ID (e.g., mas_1_dev_team)",
    )
    parser.add_argument(
        "--model",
        default=None,
        help="Filter by model name (substring match)",
    )
    parser.add_argument(
        "--include-summaries",
        action="store_true",
        help="Include transcript summaries in output",
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Verbose output",
    )

    args = parser.parse_args()

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(levelname)s: %(message)s",
    )

    # Discover result files
    paths = [Path(p) for p in args.paths]
    result_files = discover_result_files(paths)
    logger.info("Discovered %d result files", len(result_files))

    if not result_files:
        logger.error("No result files found in: %s", args.paths)
        sys.exit(1)

    # Aggregate
    records, summary_stats = aggregate_results(
        result_files,
        mas_filter=args.mas,
        model_filter=args.model,
        include_summaries=args.include_summaries,
    )

    if not records:
        logger.warning("No MAS task records found. Ensure results contain MAS runs (--mas flag).")
        sys.exit(0)

    logger.info("Extracted %d MAS task records", len(records))
    logger.info("Aggregated into %d summary groups", len(summary_stats))

    # Output
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    prefix = args.prefix or f"mas_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

    if args.format in ("jsonl", "both"):
        write_jsonl(records, output_dir / f"{prefix}_records.jsonl")
        write_json_summary(summary_stats, output_dir / f"{prefix}_summary.json")

    if args.format in ("csv", "both"):
        write_csv(records, output_dir / f"{prefix}_records.csv")
        write_csv_summary(summary_stats, output_dir / f"{prefix}_summary.csv")

    # Print quick summary
    print(f"\n{'='*70}")
    print(f"  MAS Results Aggregation Summary")
    print(f"{'='*70}")
    print(f"  Result files processed: {len(result_files)}")
    print(f"  MAS task records:       {len(records)}")
    print(f"  Summary groups:         {len(summary_stats)}")
    print(f"  Output directory:       {output_dir}")
    print(f"  Output prefix:          {prefix}")
    print(f"{'='*70}")

    # Print top-level ASR by MAS system
    mas_asr: Dict[str, List[float]] = defaultdict(list)
    for record in records:
        mas_asr[record.get("mas_system_id", "unknown")].append(record["attack_success"])

    print(f"\n  Attack Success Rate (ASR) by MAS System:")
    print(f"  {'MAS System':<35} {'ASR':>8} {'Tasks':>6}")
    print(f"  {'-'*35} {'-'*8} {'-'*6}")
    for mas_id in sorted(mas_asr.keys()):
        asrs = mas_asr[mas_id]
        mean_asr = sum(asrs) / len(asrs) if asrs else 0
        print(f"  {mas_id:<35} {mean_asr:>7.1%} {len(asrs):>6}")

    # Print ASR by model
    model_asr: Dict[str, List[float]] = defaultdict(list)
    for record in records:
        model_asr[record.get("model_full", "unknown")].append(record["attack_success"])

    print(f"\n  Attack Success Rate (ASR) by Model:")
    print(f"  {'Model':<45} {'ASR':>8} {'Tasks':>6}")
    print(f"  {'-'*45} {'-'*8} {'-'*6}")
    for model in sorted(model_asr.keys()):
        asrs = model_asr[model]
        mean_asr = sum(asrs) / len(asrs) if asrs else 0
        print(f"  {model:<45} {mean_asr:>7.1%} {len(asrs):>6}")

    print()


if __name__ == "__main__":
    main()