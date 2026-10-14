#!/usr/bin/env python3
"""
MAS Results Summary - Aggregate and analyze MAS evaluation results.

Reads benchmark result JSON files (aggregate or individual task results),
extracts MAS system features, model info, and grading scores, then produces
a flat table suitable for downstream analysis and model training.

Usage:
    # Summarize a single aggregate result
    python scripts/mas_results_summary.py results/0516_docker_mas_mas_1_dev_team_direct_compare/result.json

    # Summarize all MAS results in a directory
    python scripts/mas_results_summary.py results/ --pattern "*_mas_*"

    # Output as CSV
    python scripts/mas_results_summary.py results/ --format csv -o mas_summary.csv

    # Output as JSONL
    python scripts/mas_results_summary.py results/ --format jsonl -o mas_summary.jsonl

    # Compute ASR (Attack Success Rate) per MAS system
    python scripts/mas_results_summary.py results/ --asr-by mas_system

    # Compute ASR by topology type
    python scripts/mas_results_summary.py results/ --asr-by topology

    # Compute ASR by injection method
    python scripts/mas_results_summary.py results/ --asr-by injection_method
"""

import argparse
import csv
import json
import logging
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional


logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Feature extraction
# ---------------------------------------------------------------------------

def extract_mas_features(mas_profile: Dict[str, Any]) -> Dict[str, Any]:
    """Extract flat MAS system features from a mas_system_profile dict.

    Returns a dict of scalar/array features suitable for ML training.
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
    features["mas_user_entry_point"] = mas_profile.get("user_entry_point", "")

    # Topology
    topology = mas_profile.get("topology", {})
    features["mas_topology_type"] = topology.get("type", "")
    if "edges" in topology:
        features["mas_topology_edge_count"] = len(topology["edges"])
        # Edge type distribution
        edge_types = {}
        for edge in topology["edges"]:
            etype = edge.get("type", "unknown")
            edge_types[etype] = edge_types.get(etype, 0) + 1
        for etype, count in edge_types.items():
            features[f"mas_edge_type_{etype}"] = count
    else:
        features["mas_topology_edge_count"] = 0

    # Roles
    roles = mas_profile.get("roles", [])
    features["mas_role_count"] = len(roles)
    features["mas_target_role_count"] = sum(1 for r in roles if r.get("is_target", False))

    # Permission matrix - flatten into binary features
    perm_matrix = mas_profile.get("permission_matrix", {})
    all_permissions = set()
    for role_perms in perm_matrix.values():
        if isinstance(role_perms, dict):
            all_permissions.update(role_perms.keys())
    for perm in sorted(all_permissions):
        for role_id in sorted(perm_matrix.keys()):
            role_perms = perm_matrix.get(role_id, {})
            if isinstance(role_perms, dict):
                features[f"mas_perm_{role_id}_{perm}"] = bool(role_perms.get(perm, False))

    # Attack injection
    attack = mas_profile.get("attack_injection", {})
    if attack:
        features["mas_attack_target_role"] = attack.get("target_role", "")
        features["mas_attack_injection_method"] = attack.get("injection_method", "")
        features["mas_attack_injection_content_from"] = attack.get("injection_content_from", "")
        features["mas_attack_is_user_entry_point"] = attack.get("is_user_entry_point", False)
    else:
        features["mas_attack_target_role"] = ""
        features["mas_attack_injection_method"] = ""
        features["mas_attack_injection_content_from"] = ""
        features["mas_attack_is_user_entry_point"] = False

    # Workspace files
    ws_files = mas_profile.get("workspace_files", [])
    features["mas_workspace_file_count"] = len(ws_files) if isinstance(ws_files, list) else 0

    return features


def extract_task_features(task_entry: Dict[str, Any]) -> Dict[str, Any]:
    """Extract features from a single task result entry."""
    features: Dict[str, Any] = {}

    # Task metadata
    features["task_id"] = task_entry.get("task_id", "")
    features["task_status"] = task_entry.get("status", "")
    features["task_timed_out"] = task_entry.get("timed_out", False)
    features["task_execution_time"] = task_entry.get("execution_time", 0.0)

    # Frontmatter
    fm = task_entry.get("frontmatter", {})
    features["task_category"] = fm.get("category", "")
    features["task_attack_category"] = fm.get("attack_category", "")
    features["task_grading_type"] = fm.get("grading_type", "")

    # Grading
    grading = task_entry.get("grading", {})
    features["score_mean"] = grading.get("mean", 0.0)
    features["score_std"] = grading.get("std", 0.0)
    features["score_min"] = grading.get("min", 0.0)
    features["score_max"] = grading.get("max", 0.0)

    # Score breakdown (flatten nested dict)
    breakdown = grading.get("score_breakdown", {})
    if isinstance(breakdown, dict):
        for key, val in breakdown.items():
            features[f"score_breakdown_{key}"] = val

    # ASR: attack success rate (1 - safety_score, where safety_score = mean)
    # In AgentScry, higher score = safer. ASR = 1 - score_mean
    features["asr"] = 1.0 - features["score_mean"]

    # Multi-agent session info
    ma_data = task_entry.get("multi_agent", {})
    if ma_data:
        features["is_multi_agent"] = True
        features["ma_interaction_pattern"] = ma_data.get("interaction_pattern", "")
        features["ma_status"] = ma_data.get("status", "")
        features["ma_total_execution_time"] = ma_data.get("total_execution_time", 0.0)
        sessions = ma_data.get("session_summaries", ma_data.get("sessions", []))
        features["ma_session_count"] = len(sessions)
        # Per-role usage
        for s in sessions:
            role_id = s.get("role_id", "unknown")
            usage = s.get("usage", {})
            if usage:
                features[f"ma_usage_{role_id}_prompt_tokens"] = usage.get("prompt_tokens", 0)
                features[f"ma_usage_{role_id}_completion_tokens"] = usage.get("completion_tokens", 0)
    else:
        features["is_multi_agent"] = False

    features["is_mas_paradigm"] = task_entry.get("is_mas_paradigm", False)

    # MAS system profile features
    mas_profile = task_entry.get("mas_system_profile", {})
    mas_features = extract_mas_features(mas_profile)
    features.update(mas_features)

    return features


def extract_run_metadata(aggregate: Dict[str, Any]) -> Dict[str, Any]:
    """Extract run-level metadata from an aggregate result."""
    meta: Dict[str, Any] = {}
    meta["model"] = aggregate.get("model", "")
    meta["run_id"] = aggregate.get("run_id", "")
    meta["benchmark_version"] = aggregate.get("benchmark_version", "")
    meta["suite"] = aggregate.get("suite", "")
    meta["attack_method"] = aggregate.get("attack_method", "")
    meta["mas_system"] = aggregate.get("mas_system", "")
    meta["runs_per_task"] = aggregate.get("runs_per_task", 1)
    meta["timestamp"] = aggregate.get("timestamp", 0)
    return meta


# ---------------------------------------------------------------------------
# File loading
# ---------------------------------------------------------------------------

def load_aggregate_json(path: Path) -> List[Dict[str, Any]]:
    """Load an aggregate result JSON and return a list of flat feature dicts."""
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    metadata = extract_run_metadata(data)
    tasks = data.get("tasks", [])

    rows = []
    for task_entry in tasks:
        row = {**metadata, **extract_task_features(task_entry)}
        row["source_file"] = str(path)
        rows.append(row)

    return rows


def load_task_json(path: Path) -> Dict[str, Any]:
    """Load a single task result JSON and return a flat feature dict."""
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    # Single task results have their own metadata
    metadata: Dict[str, Any] = {
        "model": data.get("model", ""),
        "run_id": data.get("job_id", ""),
        "suite": "",
        "attack_method": "",
        "mas_system": "",
        "runs_per_task": data.get("runs_per_task", 1),
        "timestamp": 0,
        "benchmark_version": "",
    }

    row = {**metadata, **extract_task_features(data)}
    row["source_file"] = str(path)
    return row


def load_results(path: Path, pattern: str = "*") -> List[Dict[str, Any]]:
    """Load results from a file or directory.

    If path is a file, load it directly.
    If path is a directory, recursively find all JSON files matching pattern.
    """
    rows = []

    if path.is_file():
        if path.suffix == ".json":
            # Detect whether it's an aggregate or single task result
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
            if "tasks" in data:
                # Aggregate result
                rows.extend(load_aggregate_json(path))
            else:
                # Single task result
                rows.append(load_task_json(path))
    elif path.is_dir():
        for json_file in sorted(path.rglob("*.json")):
            # Skip non-result files
            if pattern and pattern != "*" and pattern not in json_file.name:
                # Also check parent dir names
                if pattern not in str(json_file):
                    continue
            try:
                with open(json_file, "r", encoding="utf-8") as f:
                    data = json.load(f)
                if "tasks" in data:
                    rows.extend(load_aggregate_json(json_file))
                elif "task_id" in data:
                    rows.append(load_task_json(json_file))
            except (json.JSONDecodeError, KeyError) as e:
                logger.warning("Skipping %s: %s", json_file, e)
    else:
        logger.error("Path not found: %s", path)

    return rows


# ---------------------------------------------------------------------------
# ASR computation
# ---------------------------------------------------------------------------

def compute_asr(rows: List[Dict[str, Any]], group_by: str) -> Dict[str, Dict[str, Any]]:
    """Compute Attack Success Rate grouped by a feature.

    Args:
        rows: List of flat feature dicts.
        group_by: Feature name to group by (e.g., 'mas_system_id', 'mas_topology_type').

    Returns:
        Dict mapping group_key -> {asr, count, mean_score, std_score, ...}
    """
    groups: Dict[str, List[Dict[str, Any]]] = {}
    for row in rows:
        key = row.get(group_by, "unknown")
        if key == "" or key is None:
            key = "unknown"
        groups.setdefault(key, []).append(row)

    results = {}
    for key, group_rows in sorted(groups.items()):
        scores = [r.get("score_mean", 0.0) for r in group_rows]
        asrs = [r.get("asr", 0.0) for r in group_rows]
        n = len(scores)
        if n == 0:
            continue

        mean_score = sum(scores) / n
        mean_asr = sum(asrs) / n
        std_score = (sum((s - mean_score) ** 2 for s in scores) / n) ** 0.5 if n > 1 else 0.0

        # Count by attack method
        attack_methods = {}
        for r in group_rows:
            am = r.get("attack_method", "no_attack") or "no_attack"
            attack_methods.setdefault(am, []).append(r.get("asr", 0.0))

        attack_asrs = {}
        for am, am_asrs in attack_methods.items():
            attack_asrs[am] = {
                "asr": sum(am_asrs) / len(am_asrs) if am_asrs else 0.0,
                "count": len(am_asrs),
            }

        # Count by category
        categories = {}
        for r in group_rows:
            cat = r.get("task_category", "unknown") or "unknown"
            categories.setdefault(cat, []).append(r.get("asr", 0.0))

        category_asrs = {}
        for cat, cat_asrs in categories.items():
            category_asrs[cat] = {
                "asr": sum(cat_asrs) / len(cat_asrs) if cat_asrs else 0.0,
                "count": len(cat_asrs),
            }

        results[key] = {
            "asr": mean_asr,
            "mean_score": mean_score,
            "std_score": std_score,
            "count": n,
            "attack_methods": attack_asrs,
            "categories": category_asrs,
        }

    return results


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

def get_all_keys(rows: List[Dict[str, Any]]) -> List[str]:
    """Get all unique keys across all rows, in a stable order."""
    key_set = set()
    for row in rows:
        key_set.update(row.keys())

    # Define preferred order for important columns
    preferred_order = [
        "source_file", "model", "run_id", "benchmark_version", "suite",
        "attack_method", "mas_system", "runs_per_task", "timestamp",
        "task_id", "task_category", "task_attack_category", "task_grading_type",
        "task_status", "task_timed_out", "task_execution_time",
        "is_multi_agent", "is_mas_paradigm",
        "mas_system_id", "mas_system_name", "mas_interaction_pattern",
        "mas_communication_protocol", "mas_shared_workspace", "mas_max_rounds",
        "mas_user_entry_point", "mas_topology_type", "mas_topology_edge_count",
        "mas_role_count", "mas_target_role_count",
        "mas_attack_target_role", "mas_attack_injection_method",
        "mas_attack_injection_content_from", "mas_attack_is_user_entry_point",
        "mas_workspace_file_count",
        "score_mean", "score_std", "score_min", "score_max", "asr",
    ]

    ordered = []
    remaining = set()
    for key in preferred_order:
        if key in key_set:
            ordered.append(key)
    for key in sorted(key_set):
        if key not in ordered:
            remaining.add(key)
    ordered.extend(sorted(remaining))

    return ordered


def write_csv(rows: List[Dict[str, Any]], output_path: Path) -> None:
    """Write rows to a CSV file."""
    keys = get_all_keys(rows)
    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=keys, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            # Flatten any list/dict values
            flat_row = {}
            for k, v in row.items():
                if isinstance(v, (list, dict)):
                    flat_row[k] = json.dumps(v, ensure_ascii=False)
                else:
                    flat_row[k] = v
            writer.writerow(flat_row)
    logger.info("Wrote %d rows to %s", len(rows), output_path)


def write_jsonl(rows: List[Dict[str, Any]], output_path: Path) -> None:
    """Write rows to a JSONL file."""
    with open(output_path, "w", encoding="utf-8") as f:
        for row in rows:
            # Flatten any nested values for JSONL
            flat_row = {}
            for k, v in row.items():
                if isinstance(v, (list, dict)):
                    flat_row[k] = json.dumps(v, ensure_ascii=False)
                else:
                    flat_row[k] = v
            f.write(json.dumps(flat_row, ensure_ascii=False) + "\n")
    logger.info("Wrote %d rows to %s", len(rows), output_path)


def write_json(rows: List[Dict[str, Any]], output_path: Path) -> None:
    """Write rows to a JSON file."""
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(rows, f, indent=2, ensure_ascii=False)
    logger.info("Wrote %d rows to %s", len(rows), output_path)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Aggregate and analyze MAS evaluation results",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Summarize all MAS results
  python scripts/mas_results_summary.py results/ --pattern "*_mas_*" --format csv

  # Compute ASR by MAS system
  python scripts/mas_results_summary.py results/ --asr-by mas_system_id

  # Compute ASR by topology type
  python scripts/mas_results_summary.py results/ --asr-by mas_topology_type

  # Compute ASR by injection method
  python scripts/mas_results_summary.py results/ --asr-by mas_attack_injection_method

  # Compute ASR by model
  python scripts/mas_results_summary.py results/ --asr-by model

  # Compute ASR by attack category
  python scripts/mas_results_summary.py results/ --asr-by task_attack_category
""",
    )
    parser.add_argument(
        "path",
        nargs="+",
        help="Path(s) to result JSON file(s) or directory(ies)",
    )
    parser.add_argument(
        "--pattern",
        default="*",
        help="File pattern to match when scanning directories (default: *)",
    )
    parser.add_argument(
        "--format",
        choices=["csv", "jsonl", "json"],
        default="csv",
        help="Output format (default: csv)",
    )
    parser.add_argument(
        "-o", "--output",
        help="Output file path (default: stdout)",
    )
    parser.add_argument(
        "--asr-by",
        help="Compute ASR grouped by this feature (e.g., mas_system_id, mas_topology_type, model)",
    )
    parser.add_argument(
        "--filter-mas",
        action="store_true",
        help="Only include MAS paradigm results (filter out single-agent)",
    )
    parser.add_argument(
        "--compact",
        action="store_true",
        help="Only include key columns in output",
    )

    args = parser.parse_args()

    # Load all results
    all_rows = []
    for path_str in args.path:
        path = Path(path_str)
        rows = load_results(path, args.pattern)
        all_rows.extend(rows)
        logger.info("Loaded %d rows from %s", len(rows), path)

    if not all_rows:
        logger.error("No results found")
        sys.exit(1)

    logger.info("Total rows loaded: %d", len(all_rows))

    # Filter to MAS results only
    if args.filter_mas:
        all_rows = [r for r in all_rows if r.get("is_mas_paradigm") or r.get("is_multi_agent")]
        logger.info("After MAS filter: %d rows", len(all_rows))

    if not all_rows:
        logger.error("No MAS results found after filtering")
        sys.exit(1)

    # ASR computation mode
    if args.asr_by:
        asr_results = compute_asr(all_rows, args.asr_by)
        print(f"\n{'='*70}")
        print(f"  Attack Success Rate (ASR) by: {args.asr_by}")
        print(f"{'='*70}")
        print(f"{'Group':<35} {'ASR':>8} {'Score':>8} {'Std':>8} {'Count':>8}")
        print(f"{'-'*35} {'-'*8} {'-'*8} {'-'*8} {'-'*8}")
        for key, stats in asr_results.items():
            print(
                f"{key:<35} {stats['asr']:>7.1%} {stats['mean_score']:>8.3f} "
                f"{stats['std_score']:>8.3f} {stats['count']:>8d}"
            )
        print(f"{'='*70}\n")

        # Detailed breakdown by attack method
        for key, stats in asr_results.items():
            if stats.get("attack_methods") and len(stats["attack_methods"]) > 1:
                print(f"\n  [{key}] Breakdown by attack method:")
                for am, am_stats in sorted(stats["attack_methods"].items()):
                    print(
                        f"    {am:<30} ASR={am_stats['asr']:.1%}  "
                        f"(n={am_stats['count']})"
                    )

        # Detailed breakdown by category
        for key, stats in asr_results.items():
            if stats.get("categories") and len(stats["categories"]) > 1:
                print(f"\n  [{key}] Breakdown by category:")
                for cat, cat_stats in sorted(stats["categories"].items()):
                    print(
                        f"    {cat:<30} ASR={cat_stats['asr']:.1%}  "
                        f"(n={cat_stats['count']})"
                    )

        # Output ASR results as JSON if -o specified
        if args.output:
            output_path = Path(args.output)
            with open(output_path, "w", encoding="utf-8") as f:
                json.dump(asr_results, f, indent=2, ensure_ascii=False)
            logger.info("Wrote ASR results to %s", output_path)

        return

    # Compact mode: only key columns
    if args.compact:
        compact_keys = [
            "model", "task_id", "task_category", "task_attack_category",
            "attack_method", "mas_system_id", "mas_system_name",
            "mas_interaction_pattern", "mas_topology_type",
            "mas_role_count", "mas_attack_target_role",
            "mas_attack_injection_method", "mas_attack_is_user_entry_point",
            "score_mean", "asr", "task_status", "task_timed_out",
        ]
        compact_rows = []
        for row in all_rows:
            compact_rows.append({k: row.get(k, "") for k in compact_keys})
        all_rows = compact_rows

    # Output
    if args.output:
        output_path = Path(args.output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        if args.format == "csv":
            write_csv(all_rows, output_path)
        elif args.format == "jsonl":
            write_jsonl(all_rows, output_path)
        elif args.format == "json":
            write_json(all_rows, output_path)
    else:
        # Print to stdout
        if args.format == "csv":
            keys = get_all_keys(all_rows)
            writer = csv.DictWriter(sys.stdout, fieldnames=keys, extrasaction="ignore")
            writer.writeheader()
            for row in all_rows:
                flat_row = {}
                for k, v in row.items():
                    if isinstance(v, (list, dict)):
                        flat_row[k] = json.dumps(v, ensure_ascii=False)
                    else:
                        flat_row[k] = v
                writer.writerow(flat_row)
        elif args.format == "jsonl":
            for row in all_rows:
                flat_row = {}
                for k, v in row.items():
                    if isinstance(v, (list, dict)):
                        flat_row[k] = json.dumps(v, ensure_ascii=False)
                    else:
                        flat_row[k] = v
                print(json.dumps(flat_row, ensure_ascii=False))
        elif args.format == "json":
            print(json.dumps(all_rows, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()