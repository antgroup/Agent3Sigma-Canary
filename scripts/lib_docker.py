"""
Docker runtime abstraction for AgentCanary.

Provides a clean interface that lib_agent.py calls for all subprocess and
transcript operations. When docker mode is inactive, calls pass through
directly. When active, commands are wrapped with 'docker exec' and
transcripts are copied from the container before reading.

Key abstractions:
  1. run_cmd()       — execute openclaw CLI (transparent docker exec wrapping)
  2. ensure_transcripts_on_host() — make transcript files readable on host
  3. restart()       — full environment reset (for PAIR iterations)
"""

from __future__ import annotations

import logging
import subprocess
import time
import uuid
from pathlib import Path
import os


logger = logging.getLogger(__name__)

DOCKER_IMAGE = os.environ.get("DOCKER_IMAGE", "openclaw-bench")
DOCKER_TRANSCRIPT_DIR = Path("/tmp/scry/.docker-transcripts")

# Resource limits (to prevent fork bomb and resource exhaustion attacks)
DOCKER_PIDS_LIMIT = int(os.environ.get("DOCKER_PIDS_LIMIT", "128"))  # Max processes
DOCKER_MEMORY_LIMIT = os.environ.get("DOCKER_MEMORY_LIMIT", "4g")    # Memory limit
DOCKER_CPU_LIMIT = os.environ.get("DOCKER_CPU_LIMIT", "2")           # CPU cores

# Disk I/O limits — prevent container writes from exhausting host disk via
# overlay2 (which has no per-container storage quota on ext4).
#
# Defence strategy (cgroup v1 + overlay2/ext4):
#   1. --tmpfs /var/tmp:size=5g  → dd-style attacks targeting /var/tmp are
#      capped in RAM; writes never touch host disk.
#   2. --memory-swap equal to --memory → disables per-container swap so that
#      overlay2 page-cache writes are charged to the container cgroup and
#      cannot balloon into host memory.
#   3. --device-write-bps kept as defence-in-depth; only added when the block
#      device exists (Linux). On macOS Docker Desktop the VM uses a different
#      device path and cgroup v1 blkio does NOT throttle overlay2 buffered
#      writes anyway, so the flag is skipped.
DOCKER_DEVICE_WRITE_BPS = os.environ.get("DOCKER_DEVICE_WRITE_BPS", "10m")
DOCKER_DEVICE_READ_BPS = os.environ.get("DOCKER_DEVICE_READ_BPS", "100m")
DOCKER_BLOCK_DEVICE = os.environ.get("DOCKER_BLOCK_DEVICE", "/dev/sda")
DOCKER_TMPFS_VAR_TMP_SIZE = os.environ.get("DOCKER_TMPFS_VAR_TMP_SIZE", "4g")

# ---------------------------------------------------------------------------
# Module state
# ---------------------------------------------------------------------------
_container_id: str | None = None


# ---------------------------------------------------------------------------
# Public API: query state
# ---------------------------------------------------------------------------

def is_active() -> bool:
    """Return True if currently running in Docker mode."""
    return _container_id is not None


def get_container_id() -> str | None:
    """Return the current Docker container ID, or None."""
    return _container_id


# ---------------------------------------------------------------------------
# Public API: command execution
# ---------------------------------------------------------------------------

def run_cmd(
    args: list[str],
    *,
    capture_output: bool = True,
    text: bool = True,
    check: bool = False,
    timeout: float | None = None,
    cwd: str | None = None,
) -> subprocess.CompletedProcess:
    """Run a CLI command, optionally inside a Docker container.

    When docker mode is active, prepends 'docker exec' and translates
    the cwd parameter to a '-w' flag (since the host cwd is meaningless
    inside the container).
    """
    if _container_id:
        # In Docker mode, ensure the working directory exists in the container
        # before running the command. This prevents uv_cwd errors when
        # OpenClaw CLI tries to call process.cwd() on a non-existent directory.
        if cwd:
            # Create the directory in the container if it doesn't exist
            mkdir_cmd = ["docker", "exec", _container_id, "mkdir", "-p", cwd]
            subprocess.run(
                mkdir_cmd,
                capture_output=True,
                text=True,
                check=False,
                timeout=10,
            )
        cmd = ["docker", "exec"]
        if cwd:
            cmd += ["-w", cwd]
        cmd += [_container_id] + args
        effective_cwd = None
    else:
        cmd = args
        effective_cwd = cwd

    return subprocess.run(
        cmd,
        capture_output=capture_output,
        text=text,
        check=check,
        timeout=timeout,
        cwd=effective_cwd,
    )


# ---------------------------------------------------------------------------
# Public API: transcript access
# ---------------------------------------------------------------------------

def ensure_transcripts_on_host(agent_id: str, task_agent_workspace_root: Path) -> str:
    """Make agent transcript files available on the host filesystem.

    In local mode this is a no-op (files are already on host).
    In docker mode, runs 'docker cp' to copy them out of the container.
    """
    if not _container_id:
        return ''

    container_path = f"/root/.openclaw/agents/{agent_id}"
    local_path = str(task_agent_workspace_root) + str(DOCKER_TRANSCRIPT_DIR) +'/'+ agent_id
    Path(local_path).mkdir(parents=True, exist_ok=True)

    result = subprocess.run(
        ["docker", "cp", f"{_container_id}:{container_path}/.", str(local_path)],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        logger.warning(
            "Failed to copy transcript from container: %s", result.stderr.strip()
        )
    return local_path


def get_agent_store_base(agent_id: str) -> Path:
    """Return the base directory where agent transcripts are stored.

    In local mode:  ~/.openclaw/agents/{agent_id}
    In docker mode: /tmp/scry/.docker-transcripts/{agent_id}
    """
    if _container_id:
        return DOCKER_TRANSCRIPT_DIR / agent_id
    return Path.home() / ".openclaw" / "agents" / agent_id


# ---------------------------------------------------------------------------
# Public API: container lifecycle
# ---------------------------------------------------------------------------

def start() -> str:
    """Start a fresh Docker container with resource limits.

    Returns the container ID.

    Resource limits prevent fork bombs and resource exhaustion attacks:
    - pids-limit: Maximum number of processes (default 128)
    - memory: Memory limit (default 2g)
    - cpus: CPU cores limit (default 1)
    """
    global _container_id

    logger.info(
        "Starting container with limits: pids=%s, memory=%s, cpus=%s, "
        "device-write-bps=%s, device-read-bps=%s, tmpfs-var-tmp=%s",
        DOCKER_PIDS_LIMIT, DOCKER_MEMORY_LIMIT, DOCKER_CPU_LIMIT,
        DOCKER_DEVICE_WRITE_BPS, DOCKER_DEVICE_READ_BPS,
        DOCKER_TMPFS_VAR_TMP_SIZE,
    )

    run_args = [
        "docker", "run", "-d",
        "--name", f"agentcanary-{int(time.time())}-{uuid.uuid4().hex[:8]}",
        # "-v", "/tmp/scry:/tmp/scry",
        # Allow iptables for mock-api DNAT rules
        "--cap-add=NET_ADMIN",
        # Resource limits to prevent fork bombs
        "--pids-limit", str(DOCKER_PIDS_LIMIT),
        "--memory", DOCKER_MEMORY_LIMIT,
        # Disable per-container swap so overlay2 page-cache writes are
        # charged to the container cgroup and cannot balloon into host RAM.
        "--memory-swap", DOCKER_MEMORY_LIMIT,
        "--cpus", DOCKER_CPU_LIMIT,
        # Mount /var/tmp as tmpfs — dd-style disk-fill attacks are capped
        # at this size in RAM and never touch host disk.
        # Note: /dev is already a 64 MB tmpfs by Docker default, so attacks
        # like "dd of=/dev/sda" are naturally capped and harmless.
        "--tmpfs", f"/var/tmp:rw,size={DOCKER_TMPFS_VAR_TMP_SIZE}",
    ]

    # Disk I/O limits — only added when the block device exists on the host.
    # On macOS Docker Desktop the VM uses /dev/vda (not /dev/sda), and cgroup
    # v1 blkio doesn't throttle overlay2 buffered writes anyway.
    if os.path.exists(DOCKER_BLOCK_DEVICE):
        run_args += [
            "--device-write-bps", f"{DOCKER_BLOCK_DEVICE}:{DOCKER_DEVICE_WRITE_BPS}",
            "--device-read-bps", f"{DOCKER_BLOCK_DEVICE}:{DOCKER_DEVICE_READ_BPS}",
        ]

    run_args.append(DOCKER_IMAGE)

    result = subprocess.run(
        run_args,
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"Failed to start Docker container: {result.stderr.strip()}"
        )

    _container_id = result.stdout.strip()
    logger.info("Started Docker container: %s", _container_id[:12])
    return _container_id


def stop() -> None:
    """Stop and remove the current Docker container."""
    global _container_id

    if not _container_id:
        return

    subprocess.run(
        ["docker", "rm", "-f", _container_id],
        capture_output=True,
        text=True,
        check=False,
    )
    logger.info("Stopped Docker container: %s", _container_id[:12])
    _container_id = None


def restart() -> str:
    """Stop current container and start a fresh one.

    Used by PAIR attack iterations to get a clean environment.
    Returns the new container ID.
    """
    stop()
    return start()


def copy_to_container(host_path: str, container_dest: Path) -> bool:
    """Copy directory contents from host to Docker container.

    Equivalent to: docker cp host_path/. container:container_dest

    Args:
        host_path: Path on host to copy from (contents will be copied)
        container_dest: Destination directory inside container

    Returns:
        True if copy succeeded, False otherwise
    """
    if not _container_id:
        logger.warning("Cannot copy: no active container")
        return False

    try:
        # Copy tar to container temp location
        result = subprocess.run(
            ["docker", "cp", str(host_path), f"{_container_id}:{container_dest}"],
            capture_output=True,
            text=True,
            check=False,
        )
        if result.returncode != 0:
            logger.warning("Failed to copy tar to container: %s", result.stderr)
            return False
        return True
    finally:
        logger.info("Copied %s to %s", host_path, container_dest)
