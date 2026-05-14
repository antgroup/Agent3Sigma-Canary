"""
Tracee container management for PinchBench.

Provides container lifecycle management for tracee monitoring.
When active, starts a tracee container that monitors the test container
and outputs logs to the tracee_logs/ directory.

Key functions:
- start(): Start tracee container to monitor target container
- stop(): Stop tracee container and collect logs
- is_active(): Check if tracee container is running
- rename_log_for_task(): Rename log file with task ID and timestamp
"""

from __future__ import annotations

import logging
import subprocess
import time
import uuid
from pathlib import Path
from typing import Optional

import yaml


logger = logging.getLogger(__name__)

# Default tracee Docker image
TRACEE_IMAGE = "aquasec/tracee:latest"

# Default output directory (relative to project root)
DEFAULT_OUTPUT_DIR = Path("tracee_logs")

# Module state
_tracee_container_id: Optional[str] = None
_output_dir: Optional[Path] = None


# ---------------------------------------------------------------------------
# Public API: query state
# ---------------------------------------------------------------------------

def is_active() -> bool:
    """Return True if tracee container is currently running."""
    return _tracee_container_id is not None


def get_tracee_container_id() -> Optional[str]:
    """Return the current tracee container ID, or None."""
    return _tracee_container_id


def get_output_dir() -> Optional[Path]:
    """Return the output directory for tracee logs."""
    return _output_dir


# ---------------------------------------------------------------------------
# Public API: container lifecycle
# ---------------------------------------------------------------------------

def start(
    target_container_id: str,
    output_dir: Optional[Path] = None,
    config_path: Optional[Path] = None,
) -> Optional[str]:
    """Start a tracee container to monitor the target container.

    Args:
        target_container_id: The Docker container ID to monitor
        output_dir: Directory to output tracee logs (default: ./tracee_logs/)
        config_path: Path to tracee_config.yaml (optional)

    Returns:
        The tracee container ID, or None if failed
    """
    global _tracee_container_id, _output_dir

    if _tracee_container_id:
        logger.warning("Tracee container already running: %s", _tracee_container_id[:12])
        return _tracee_container_id

    # Set output directory
    _output_dir = output_dir or DEFAULT_OUTPUT_DIR
    _output_dir.mkdir(parents=True, exist_ok=True)

    # Convert to absolute path for Docker mount
    abs_output_dir = _output_dir.resolve()

    # Load configuration if provided
    config = _load_config(config_path)

    # Build tracee command
    tracee_cmd = _build_tracee_command(target_container_id, config)

    # Build docker run command
    container_name = f"tracee-{int(time.time())}-{uuid.uuid4().hex[:8]}"

    docker_cmd = [
        "docker", "run", "-d",
        "--name", container_name,
        # Required for eBPF tracing
        "--privileged",
        # Required for container monitoring
        "--pid=host",
        "--cgroupns=host",
        # Mount output directory
        "-v", f"{abs_output_dir}:/output",
        # Required mounts for tracee
        "-v", "/etc/os-release:/etc/os-release-host:ro",
        "-v", "/var/run:/var/run:ro",
        "-v", "/lib/modules:/lib/modules:ro",
        "-v", "/usr/src:/usr/src:ro",
        # Tracee image
        TRACEE_IMAGE,
    ] + tracee_cmd

    logger.info("Starting tracee container to monitor: %s", target_container_id[:12])

    result = subprocess.run(
        docker_cmd,
        capture_output=True,
        text=True,
        check=False,
    )

    if result.returncode != 0:
        logger.warning("Failed to start tracee container: %s", result.stderr.strip())
        return None

    _tracee_container_id = result.stdout.strip()
    logger.info("Started tracee container: %s", _tracee_container_id[:12])
    return _tracee_container_id


def stop() -> None:
    """Stop and remove the tracee container."""
    global _tracee_container_id

    if not _tracee_container_id:
        return

    logger.info("Stopping tracee container: %s", _tracee_container_id[:12])

    # Capture logs before stopping (tracee outputs to stdout/stderr)
    if _output_dir:
        log_file = _output_dir / "tracee_events.jsonl"
        try:
            result = subprocess.run(
                ["docker", "logs", _tracee_container_id],
                capture_output=True,
                text=True,
                check=False,
            )
            # Combine stdout and stderr (tracee may output to either)
            combined_output = result.stdout + result.stderr
            if combined_output.strip():
                # Post-processing: filter out noise paths (cache only)
                # Note: node_modules paths are now included to capture skill file reads
                import json
                filtered_lines = []
                total_lines = 0
                filtered_count = 0

                for line in combined_output.strip().split("\n"):
                    line = line.strip()
                    if not line:
                        continue
                    total_lines += 1

                    try:
                        data = json.loads(line)
                        # Check if this is a security_file_open event
                        if data.get("eventName") == "security_file_open":
                            args = data.get("args", [])
                            pathname = next((a.get("value") for a in args if a.get("name") == "pathname"), None)
                            if pathname:
                                # Filter out cache paths only (node_modules now included)
                                if "cache" in pathname.lower():
                                    filtered_count += 1
                                    continue
                        filtered_lines.append(line)
                    except json.JSONDecodeError:
                        # Keep non-JSON lines (like tracee warnings)
                        filtered_lines.append(line)

                # Write filtered logs
                filtered_output = "\n".join(filtered_lines)
                log_file.write_text(filtered_output)
                logger.info("Saved tracee logs to: %s (%d bytes, %d/%d events filtered)",
                           log_file, len(filtered_output), filtered_count, total_lines)
            else:
                logger.warning("Tracee container produced no output")
        except Exception as e:
            logger.warning("Error capturing tracee logs: %s", e)

    # Stop the container gracefully first
    subprocess.run(
        ["docker", "stop", "-t", "5", _tracee_container_id],
        capture_output=True,
        text=True,
        check=False,
    )

    # Remove the container
    subprocess.run(
        ["docker", "rm", "-f", _tracee_container_id],
        capture_output=True,
        text=True,
        check=False,
    )

    logger.info("Stopped tracee container: %s", _tracee_container_id[:12])
    _tracee_container_id = None


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _load_config(config_path: Optional[Path]) -> dict:
    """Load tracee configuration from YAML file."""
    if not config_path:
        # Try default location
        default_config = Path("tracee_config.yaml")
        if default_config.exists():
            config_path = default_config

    if not config_path or not config_path.exists():
        return {}

    try:
        with open(config_path, "r") as f:
            return yaml.safe_load(f) or {}
    except Exception as e:
        logger.warning("Failed to load tracee config: %s", e)
        return {}


def _build_tracee_command(target_container_id: str, config: dict) -> list[str]:
    """Build tracee command arguments based on configuration.

    Tracee event mapping reference:
    - Process events: execve, sched_process_exec, sched_process_fork, sched_process_exit
    - Network events: security_socket_connect, security_socket_bind, security_socket_accept
    - File events: security_file_open, security_file_permission
    - Security events: security_bprm_check (ELF execution check)
    - Memory events: memfd_create, security_mmap_file, security_file_mprotect

    View all available events with:
        docker run --rm --privileged -v /etc/os-release:/etc/os-release-host:ro \\
            aquasec/tracee:latest list

    Args:
        target_container_id: The container ID to monitor
        config: Configuration dict from tracee_config.yaml

    Returns:
        List of command arguments for tracee (container entrypoint is already 'tracee')
    """
    cmd = []

    # Output format (json to stdout, we'll capture via docker logs)
    cmd.extend(["--output", "json"])

    # Scope to target container
    cmd.extend(["--scope", f"container={target_container_id}"])

    # Note: Runtime path filtering is not supported by tracee for contains patterns.
    # Filtering will be done in post-processing (stop() function).

    # Event types from config
    events = config.get("events", [])
    logger.info("Tracee config events: %s", events)
    if events and "all" not in events:
        # Correct tracee event name mapping
        # Each category can include multiple events for more complete monitoring
        event_mapping = {
            # Process events: capture process creation, execution, and exit
            "process": [
                "execve",              # Syscall level
                "execveat",            # execve with file descriptor (for memfd execution)
                "sched_process_exec",  # Scheduler level process execution (default event)
                "sched_process_fork",  # Process creation (parent -> child)
                "sched_process_exit",  # Process exit
                "security_bprm_check", # LSM hook: ELF execution check
            ],
            # Network events: capture socket connections
            "network": [
                "security_socket_connect",  # Socket connect (default event)
                "security_socket_bind",     # Socket bind
                "security_socket_accept",   # Socket accept
                "security_socket_create",   # Socket create
            ],
            # File events: capture file access
            "file": [
                "security_file_open",       # File open (currently used)
            ],
            # Signal events
            "signals": [
                "signal_detect",  # Signal detection
            ],
            # DNS events: capture DNS query and response
            "dns": [
                "net_packet_dns",  # DNS packet capture (queries and responses)
            ],
            # Memory events: capture memory execution and mapping
            "memory": [
                "memfd_create",            # Create memory file (shellcode staging)
                "security_mmap_file",      # LSM hook: file mmap (detect library loading)
                "security_file_mprotect",  # LSM hook: mprotect (detect WX->RX conversion)
                "mprotect",                # Syscall: change memory protection
            ],
            # Direct event names (pass-through)
            "net_packet_dns": ["net_packet_dns"],
        }
        tracee_events = []
        for event in events:
            if event in event_mapping:
                tracee_events.extend(event_mapping[event])

        if tracee_events:
            # Remove duplicates
            tracee_events = list(set(tracee_events))
            logger.info("Tracee events to monitor: %s", tracee_events)
            cmd.extend(["--events", ",".join(tracee_events)])

    return cmd


def get_log_path(task_id: str) -> Path:
    """Get the expected tracee log path for a task.

    Args:
        task_id: The task ID (e.g., "task_5049")

    Returns:
        Path to the tracee log file
    """
    if _output_dir:
        # 使用任务文件夹结构: tracee_logs/{task_id}/tracee.json
        task_dir = _output_dir / task_id
        return task_dir / "tracee.json"
    task_dir = DEFAULT_OUTPUT_DIR / task_id
    return task_dir / "tracee.json"


def get_task_log_dir(task_id: str, timestamp: str | None = None) -> Path:
    """Get the log directory for a specific task.

    Creates the directory if it doesn't exist.

    Args:
        task_id: The task ID (e.g., "task_5049")
        timestamp: Optional timestamp suffix (e.g., "20260420_005612").
                   If None, uses current time.

    Returns:
        Path to the task's log directory
    """
    if timestamp is None:
        from datetime import datetime
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    # 使用时间戳后缀: tracee_logs/{task_id}_{timestamp}/
    dir_name = f"{task_id}_{timestamp}"

    if _output_dir:
        task_dir = _output_dir / dir_name
    else:
        task_dir = DEFAULT_OUTPUT_DIR / dir_name

    task_dir.mkdir(parents=True, exist_ok=True)
    return task_dir


def rename_log_for_task(task_id: str, timestamp: str | None = None) -> Optional[Path]:
    """Rename the tracee log file to include the task ID and timestamp.

    Tracee outputs to tracee_events.jsonl, this renames it to tracee_logs/{task_id}_{timestamp}/tracee.json

    Args:
        task_id: The task ID (e.g., "task_5049")
        timestamp: Optional timestamp suffix (e.g., "20260420_005612").
                   If None, uses current time.

    Returns:
        Path to the renamed log file, or None if no log exists
    """
    if not _output_dir:
        return None

    source_file = _output_dir / "tracee_events.jsonl"

    # 使用任务文件夹结构: tracee_logs/{task_id}_{timestamp}/tracee.json
    task_dir = get_task_log_dir(task_id, timestamp)
    target_file = task_dir / "tracee.json"

    if not source_file.exists():
        logger.warning("No tracee log file found at: %s", source_file)
        return None

    try:
        source_file.rename(target_file)
        logger.info("Renamed tracee log to: %s", target_file)
        return target_file
    except Exception as e:
        logger.warning("Failed to rename tracee log: %s", e)
        return None