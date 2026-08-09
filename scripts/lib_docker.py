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

# Only official OpenClaw image families ship the native gateway CLI.
_NATIVE_GATEWAY_IMAGE_PREFIXES = ("openclaw-official",)
_NATIVE_GATEWAY_PORT = 18789
_NATIVE_GATEWAY_READY_TIMEOUT = float(
    os.environ.get("NATIVE_GATEWAY_READY_TIMEOUT", "30")
)
_NATIVE_GATEWAY_READY_MARKER = "[gateway] ready"

# Network egress lockdown — when explicitly enabled by benchmark.py's
# --netlock flag, agent containers may reach ONLY the configured allowlist and
# every other outbound connection is dropped. The module default is open;
# benchmark.py configures this value from the runtime flag before any container
# starts. Selected research images can opt out by image-name pattern.
#
# Allowed by the lockdown:
#   - loopback (lo) — the mock-api server lives at 127.0.0.1 and DNS-hijacked
#     skill domains are DNAT'd to loopback, so all mock traffic is local;
#   - established/related return traffic;
#   - DNS (udp/tcp 53) so the LLM hostname can resolve;
#   - the LLM provider host(s):443, resolved at lockdown time from the
#     in-container openclaw config (providers[].baseUrl) plus any extra hosts
#     in DOCKER_EGRESS_ALLOW_HOSTS (comma-separated);
#   - Package registries needed by runtime installs:
#     * registry.npmjs.org for npm install
#     * PyPI / files.pythonhosted.org via the Fastly CDN CIDRs below
#     Registry IPs rotate, so registry hosts are resolved at lockdown time and
#     CDN-backed downloads are allowed by narrow CIDRs. Override/extend via
#     DOCKER_EGRESS_ALLOW_HOSTS and DOCKER_EGRESS_ALLOW_CIDRS.
# Everything else on OUTPUT is dropped.
DOCKER_EGRESS_LOCKDOWN = False
OPEN_EGRESS_IMAGE_PATTERNS = tuple(
    part.strip()
    for part in os.environ.get(
        "DOCKER_OPEN_EGRESS_IMAGE_PATTERNS",
        "official_safety_research",
    ).split(",")
    if part.strip()
)
DEFAULT_PACKAGE_REGISTRY_HOSTS = "registry.npmjs.org"
DOCKER_EGRESS_ALLOW_HOSTS = " ".join(
    part for part in (
        DEFAULT_PACKAGE_REGISTRY_HOSTS,
        os.environ.get("DOCKER_EGRESS_ALLOW_HOSTS", ""),
    )
    if part
)
# Fastly anycast ranges fronting pypi.org and files.pythonhosted.org. These are
# from Fastly's published IP list (https://api.fastly.com/public-ip-list):
#   151.101.0.0/16  — Fastly's primary anycast block (covers pypi.org)
#   146.75.0.0/16   — Fastly anycast block
#   167.82.0.0/17   — Fastly anycast block (files.pythonhosted.org resolves here)
# Keep this list narrow and package-registry-specific. Override/extend via
# DOCKER_EGRESS_ALLOW_CIDRS.
DOCKER_EGRESS_ALLOW_CIDRS = os.environ.get(
    "DOCKER_EGRESS_ALLOW_CIDRS",
    "151.101.0.0/16,146.75.0.0/16,167.82.0.0/17",
)

# ---------------------------------------------------------------------------
# Module state
# ---------------------------------------------------------------------------
_container_id: str | None = None
# Bind mounts to apply on the next start(). Tuples of (host_path, container_path, mode)
# where mode is "ro" or "rw". Preserved across restart() so PAIR iterations keep
# the same skill subset; cleared by stop().
_extra_mounts: list[tuple[str, str, str]] = []
_defer_image_gateway = False


# ---------------------------------------------------------------------------
# Public API: query state
# ---------------------------------------------------------------------------

def is_active() -> bool:
    """Return True if currently running in Docker mode."""
    return _container_id is not None


def get_container_id() -> str | None:
    """Return the current Docker container ID, or None."""
    return _container_id


def configure_egress_lockdown(enabled: bool) -> None:
    """Set the egress policy for subsequent start()/restart() calls."""
    global DOCKER_EGRESS_LOCKDOWN
    if _container_id is not None:
        raise RuntimeError(
            "egress policy must be configured before starting the Docker container"
        )
    DOCKER_EGRESS_LOCKDOWN = bool(enabled)


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
    env: dict | None = None,
) -> subprocess.CompletedProcess:
    """Run a CLI command, optionally inside a Docker container.

    When docker mode is active, prepends 'docker exec' and translates
    the cwd parameter to a '-w' flag (since the host cwd is meaningless
    inside the container).

    ``env`` injects extra environment variables into the command's process.
    In Docker mode these become ``-e KEY=VALUE`` flags on ``docker exec`` so
    the in-container process (and any shells it spawns) sees them; in local
    mode they are merged onto the current environment. Used to expose
    per-task decoy credentials to the agent under test (pre_setup ``set_env``).
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
        if env:
            for key, value in env.items():
                cmd += ["-e", f"{key}={value}"]
        cmd += [_container_id] + args
        effective_cwd = None
        subprocess_env = None
    else:
        cmd = args
        effective_cwd = cwd
        subprocess_env = {**os.environ, **env} if env else None

    return subprocess.run(
        cmd,
        capture_output=capture_output,
        text=text,
        check=check,
        timeout=timeout,
        cwd=effective_cwd,
        env=subprocess_env,
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

def start(
    extra_mounts: list[tuple[str, str, str]] | None = None,
    *,
    defer_image_gateway: bool = False,
) -> str:
    """Start a fresh Docker container with resource limits.

    Returns the container ID.

    Resource limits prevent fork bombs and resource exhaustion attacks:
    - pids-limit: Maximum number of processes (default 128)
    - memory: Memory limit (default 2g)
    - cpus: CPU cores limit (default 1)

    extra_mounts: optional list of (host_path, container_path, mode) tuples
    to bind-mount into the container. Mode is "ro" or "rw". If not provided
    and module state _extra_mounts is non-empty, those are reused (so
    restart() preserves mounts across PAIR iterations).

    defer_image_gateway: prevent an image-managed Gateway from starting before
    the benchmark creates the per-task agent. This is used with
    benchmark.py --gateway.
    """
    global _container_id, _extra_mounts, _defer_image_gateway

    if extra_mounts is not None:
        _extra_mounts = list(extra_mounts)
    _defer_image_gateway = defer_image_gateway

    logger.info(
        "Starting container with limits: pids=%s, memory=%s, cpus=%s, "
        "device-write-bps=%s, device-read-bps=%s, tmpfs-var-tmp=%s, mounts=%d",
        DOCKER_PIDS_LIMIT, DOCKER_MEMORY_LIMIT, DOCKER_CPU_LIMIT,
        DOCKER_DEVICE_WRITE_BPS, DOCKER_DEVICE_READ_BPS,
        DOCKER_TMPFS_VAR_TMP_SIZE, len(_extra_mounts),
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

    # Per-task bind mounts (skills and any other host content injected by the
    # runner). Host paths are absolutized so relative cwd doesn't surprise.
    for host_path, container_path, mode in _extra_mounts:
        abs_host = str(Path(host_path).resolve())
        mode_flag = mode if mode in ("ro", "rw") else "ro"
        run_args += ["-v", f"{abs_host}:{container_path}:{mode_flag}"]
        logger.info("  bind mount: %s -> %s (%s)", abs_host, container_path, mode_flag)

    # Disk I/O limits — only added when the block device exists on the host.
    # On macOS Docker Desktop the VM uses /dev/vda (not /dev/sda), and cgroup
    # v1 blkio doesn't throttle overlay2 buffered writes anyway.
    if os.path.exists(DOCKER_BLOCK_DEVICE):
        run_args += [
            "--device-write-bps", f"{DOCKER_BLOCK_DEVICE}:{DOCKER_DEVICE_WRITE_BPS}",
            "--device-read-bps", f"{DOCKER_BLOCK_DEVICE}:{DOCKER_DEVICE_READ_BPS}",
        ]

    # Defer native gateway startup until the per-task agent exists. Only
    # Official OpenClaw image families use this lifecycle.
    if defer_image_gateway and _uses_native_openclaw_gateway():
        run_args += ["-e", "OPENCLAW_DEFER_GATEWAY=1"]

    # The mock-api entrypoint uses this configured URL to route the benchmark
    # web simulation domain locally. Docker does not inherit host variables
    # unless they are passed explicitly.
    web_sim_base_url = os.environ.get("WEB_SIM_BASE_URL")
    if web_sim_base_url:
        run_args += ["-e", f"WEB_SIM_BASE_URL={web_sim_base_url}"]

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
    _wait_for_mock_api_ready(_container_id)

    if _should_apply_egress_lockdown():
        _apply_egress_lockdown(_container_id)
    elif DOCKER_EGRESS_LOCKDOWN:
        logger.info(
            "Network egress lockdown skipped for open-egress image: %s",
            DOCKER_IMAGE,
        )
    else:
        logger.info("Network egress lockdown disabled for this run")

    return _container_id


def _wait_for_mock_api_ready(container_id: str, timeout_seconds: int = 20) -> None:
    """Block until mock_api's HTTP listener answers.

    All eval images run mock_api on :80 (HTTP). The neutral root response is a
    deliberate 404, so readiness accepts that response as well as the legacy
    2xx root response. Connection failures and server-side 5xx responses are
    not considered ready.

    The nanoclaw image also runs
    mock_api on :443 (HTTPS, self-signed cert) to support Claude Agent SDK's
    WebFetch http→https auto-upgrade — we wait for :443 too iff the active
    DOCKER_IMAGE tag identifies as nanoclaw. Other images (hermes, official,
    nanoclaw_openai) don't run HTTPS so we only require :80 there. Without
    this readiness gate, the agent's first WebFetch / curl can race the
    listener and get ECONNREFUSED, contaminating http_post tasks.
    """
    import time as _t
    img = os.environ.get("DOCKER_IMAGE", "").lower()
    require_https = ("nanoclaw" in img) and ("nanoclaw_openai" not in img)
    deadline = _t.time() + timeout_seconds
    checks = [
        ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", "--max-time", "2", "http://127.0.0.1:80/"],
    ]
    if require_https:
        checks.append(["curl", "-sk", "-o", "/dev/null", "-w", "%{http_code}", "--max-time", "2", "https://127.0.0.1:443/"])
    while _t.time() < deadline:
        ready = True
        for cmd in checks:
            r = subprocess.run(["docker", "exec", container_id] + cmd,
                               capture_output=True, text=True, timeout=4, check=False)
            status = r.stdout.strip()
            if not (
                r.returncode == 0
                and len(status) == 3
                and status.isdigit()
                and (200 <= int(status) <= 299 or status == "404")
            ):
                ready = False
                break
        if ready:
            return
        _t.sleep(0.5)
    logger.warning("mock_api readiness check timed out after %ds — proceeding anyway", timeout_seconds)


def _should_apply_egress_lockdown() -> bool:
    """Return whether the current Docker image should get egress lockdown."""
    if not DOCKER_EGRESS_LOCKDOWN:
        return False
    return not any(pattern in DOCKER_IMAGE for pattern in OPEN_EGRESS_IMAGE_PATTERNS)


def _uses_native_openclaw_gateway() -> bool:
    """Whether the selected image ships the native OpenClaw gateway CLI."""
    image_name = DOCKER_IMAGE.lower().rsplit("/", 1)[-1]
    return image_name.startswith(_NATIVE_GATEWAY_IMAGE_PREFIXES)


def _port_listening(container_id: str, port: int) -> bool:
    """Return whether a TCP listener exists on the given container port."""
    hex_port = f"{port:04X}"
    script = (
        "import sys\n"
        "found = False\n"
        "for path in ('/proc/net/tcp', '/proc/net/tcp6'):\n"
        "    try:\n"
        "        lines = open(path, encoding='utf-8').read().splitlines()[1:]\n"
        "    except OSError:\n"
        "        continue\n"
        "    for line in lines:\n"
        "        fields = line.split()\n"
        "        if (len(fields) > 3 and "
        "fields[1].split(':')[1].upper() == %r and fields[3] == '0A'):\n"
        "            found = True\n"
        "sys.exit(0 if found else 1)\n"
    ) % hex_port
    result = subprocess.run(
        ["docker", "exec", container_id, "python3", "-c", script],
        capture_output=True,
        text=True,
        check=False,
        timeout=10,
    )
    return result.returncode == 0


def _gateway_log_contains(container_id: str, marker: str) -> bool:
    """Return whether the native gateway log contains a readiness marker."""
    result = subprocess.run(
        [
            "docker",
            "exec",
            container_id,
            "grep",
            "-Fq",
            marker,
            "/tmp/gateway.log",
        ],
        capture_output=True,
        text=True,
        check=False,
        timeout=10,
    )
    return result.returncode == 0


def _gateway_log_tail(container_id: str, lines: int = 40) -> str:
    """Read a bounded gateway log tail for startup error reporting."""
    result = subprocess.run(
        ["docker", "exec", container_id, "tail", "-n", str(lines), "/tmp/gateway.log"],
        capture_output=True,
        text=True,
        check=False,
        timeout=10,
    )
    return (result.stdout or result.stderr).strip()


def start_image_gateway(
    timeout: float = _NATIVE_GATEWAY_READY_TIMEOUT,
    env: dict[str, str] | None = None,
) -> None:
    """Start the native in-container OpenClaw gateway after agent creation.

    Must be called AFTER the per-task agent is created (ensure_agent_exists):
    the gateway registers agents only at its startup and ignores agents added
    later, so starting it here makes it recognize and serve the new agent.
    The entrypoint defers any entrypoint-managed gateway start via the
    OPENCLAW_DEFER_GATEWAY=1 env var (set in start()). Only official-image
    families start this native service; all other frameworks retain their
    original embedded execution path. Wait for both the listener and the
    gateway's ready marker so the first agent command cannot race startup or
    the gateway's initial authentication configuration.
    """
    if not _container_id:
        return
    if not _uses_native_openclaw_gateway():
        logger.info("Skipping native gateway startup for non-official image: %s", DOCKER_IMAGE)
        return
    logger.info("Starting in-container gateway after agent creation ...")
    command = ["docker", "exec"]
    for key, value in (env or {}).items():
        command += ["-e", f"{key}={value}"]
    command += [
        _container_id,
        "sh",
        "-c",
        "setsid openclaw gateway run --allow-unconfigured "
        "> /tmp/gateway.log 2>&1 < /dev/null &",
    ]
    result = subprocess.run(
        command,
        capture_output=True, text=True, check=False, timeout=15,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"Native gateway launch command failed: {result.stderr.strip()}"
        )

    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if (
            _port_listening(_container_id, _NATIVE_GATEWAY_PORT)
            and _gateway_log_contains(_container_id, _NATIVE_GATEWAY_READY_MARKER)
        ):
            logger.info(
                "Native gateway ready on :%d",
                _NATIVE_GATEWAY_PORT,
            )
            return
        time.sleep(0.5)

    log_tail = _gateway_log_tail(_container_id)
    raise RuntimeError(
        f"Native gateway did not become ready on :{_NATIVE_GATEWAY_PORT} "
        f"within {timeout:.0f}s. Gateway log tail:\n{log_tail or '<empty>'}"
    )


# Shell script (run inside the container as root via `docker exec`) that locks
# down OUTPUT to: loopback, established/related, DNS, and the LLM provider
# host(s). The allowed hosts are discovered from the in-container openclaw
# config so we never hardcode the endpoint here; extra hosts can be appended
# via the $EXTRA_ALLOW_HOSTS env passed on the exec command line.
_EGRESS_LOCKDOWN_SCRIPT = r"""
set -u
if ! command -v iptables >/dev/null 2>&1; then
    echo "[egress-lockdown] iptables missing — cannot lock down, FAILING CLOSED is not possible" >&2
    exit 3
fi

# Collect the LLM provider hostnames from the openclaw config.
HOSTS="$(python3 - <<'PY'
import json, re
hosts=set()
try:
    d=json.load(open('/root/.openclaw/openclaw.json'))
    provs=d.get('models',{}).get('providers',{})
    for p in provs.values():
        u=p.get('baseUrl') or ''
        m=re.match(r'https?://([^/:]+)', u)
        if m: hosts.add(m.group(1))
except Exception:
    pass
print(' '.join(sorted(hosts)))
PY
)"
# Append any operator-specified extra hosts.
HOSTS="$HOSTS ${EXTRA_ALLOW_HOSTS:-}"

echo "[egress-lockdown] allowing LLM/egress hosts: $HOSTS"

# Resolve every allowed host to IPs *before* we drop egress (resolution needs
# DNS, which we keep open anyway, but resolving first is robust).
ALLOW_IPS=""
for h in $HOSTS; do
    [ -n "$h" ] || continue
    ips="$(getent ahostsv4 "$h" 2>/dev/null | awk '{print $1}' | sort -u)"
    for ip in $ips; do ALLOW_IPS="$ALLOW_IPS $ip"; done
done

# --- Build the rules ---------------------------------------------------------
# Keep loopback + established/related (mock-api is on 127.0.0.1; DNS-hijacked
# skill domains DNAT to loopback so they ride lo too).
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
# DNAT'd mock traffic: the entrypoint maps mock domains to a public-looking
# gateway IP and DNATs it to 127.0.0.1 in nat/OUTPUT (so openclaw's SSRF guard
# sees a non-private address). That rewrites the destination to loopback, but
# the OUTPUT-chain DNAT does NOT update the output interface, so the `-o lo`
# rule above misses these packets. Match by destination instead: any packet
# whose (post-DNAT) destination is loopback is local mock traffic, accept it.
iptables -A OUTPUT -d 127.0.0.0/8 -j ACCEPT
# DNS so the LLM hostname resolves.
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
# The LLM provider host(s) on 443 only.
for ip in $ALLOW_IPS; do
    iptables -A OUTPUT -d "$ip" -p tcp --dport 443 -j ACCEPT
done
# Package CDN downloads on 443. $ALLOW_CIDRS is comma-separated.
ALLOW_CIDRS="$(printf '%s' "${ALLOW_CIDRS:-}" | tr ',' ' ')"
for cidr in $ALLOW_CIDRS; do
    [ -n "$cidr" ] || continue
    iptables -A OUTPUT -d "$cidr" -p tcp --dport 443 -j ACCEPT
    echo "[egress-lockdown] allowing package CDN CIDR: $cidr:443"
done
# Default: drop everything else leaving the box.
iptables -A OUTPUT -j DROP
# Mirror onto the nat/OUTPUT-preserving chain is unnecessary: the mock DNAT
# rules already live in nat OUTPUT and run before filter OUTPUT, and their
# redirected loopback traffic is accepted by the `-d 127.0.0.0/8` rule above
# (the OUTPUT-interface is not flipped to `lo` by OUTPUT-chain DNAT, so the
# `-o lo` rule alone would miss it).

echo "[egress-lockdown] OUTPUT locked (allowed IPs:$ALLOW_IPS )"
iptables -S OUTPUT | sed 's/^/[egress-lockdown]   /'
"""


def _apply_egress_lockdown(container_id: str) -> None:
    """Lock the container's egress to the LLM API only (see module docstring).

    Runs the lockdown script inside the container as root. Raises on failure —
    we fail CLOSED: a container that can't be locked down must not run an eval.
    """
    cmd = [
        "docker", "exec",
        "-e", f"EXTRA_ALLOW_HOSTS={DOCKER_EGRESS_ALLOW_HOSTS}",
        "-e", f"ALLOW_CIDRS={DOCKER_EGRESS_ALLOW_CIDRS}",
        container_id, "bash", "-c", _EGRESS_LOCKDOWN_SCRIPT,
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if result.stdout:
        for line in result.stdout.splitlines():
            logger.info(line)
    if result.returncode != 0:
        logger.error("egress lockdown stderr: %s", result.stderr.strip())
        raise RuntimeError(
            "Failed to apply network egress lockdown — refusing to run the "
            f"eval with open network (exit {result.returncode})"
        )
    logger.info("Network egress locked to LLM API only for container %s", container_id[:12])


def stop() -> None:
    """Stop and remove the current Docker container."""
    global _container_id, _extra_mounts, _defer_image_gateway

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
    # Clear mounts so an unrelated next start() doesn't inherit stale config.
    # restart() preserves them by stopping first then starting with explicit
    # extra_mounts=None (which falls back to the just-cleared list — see note
    # in restart() below).
    _extra_mounts = []
    _defer_image_gateway = False


def restart() -> str:
    """Stop current container and start a fresh one.

    Used by PAIR attack iterations to get a clean environment.
    The previous container's bind mounts are preserved — same skill subset
    survives the restart.

    Returns the new container ID.
    """
    # Snapshot lifecycle options before stop() clears them.
    preserved_mounts = list(_extra_mounts)
    preserved_defer_gateway = _defer_image_gateway
    stop()
    return start(
        extra_mounts=preserved_mounts,
        defer_image_gateway=preserved_defer_gateway,
    )


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


def copy_dir_contents_to_container(host_dir: str, container_dest: str) -> bool:
    """Copy the *contents* of a host directory into container_dest.

    Uses the `docker cp <src>/. <cid>:<dest>` trailing-dot idiom so the source
    directory itself is not nested into the destination. Creates the
    destination directory in the container first.

    Args:
        host_dir: Source directory on the host. Its contents (not the dir
            itself) are copied.
        container_dest: Destination directory inside the container.

    Returns:
        True if copy succeeded, False otherwise.
    """
    if not _container_id:
        logger.warning("Cannot copy: no active container")
        return False
    if not Path(host_dir).is_dir():
        logger.warning("copy_dir_contents_to_container: source not a dir: %s", host_dir)
        return False

    # Ensure the destination directory exists inside the container.
    mkdir_result = subprocess.run(
        ["docker", "exec", _container_id, "mkdir", "-p", container_dest],
        capture_output=True,
        text=True,
        check=False,
        timeout=10,
    )
    if mkdir_result.returncode != 0:
        logger.warning(
            "Failed to mkdir %s in container: %s",
            container_dest, mkdir_result.stderr.strip(),
        )
        return False

    src = str(host_dir).rstrip("/") + "/."
    result = subprocess.run(
        ["docker", "cp", src, f"{_container_id}:{container_dest}"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        logger.warning(
            "docker cp failed for %s -> %s: %s",
            src, container_dest, result.stderr.strip(),
        )
        return False
    logger.info("Copied contents of %s -> %s", host_dir, container_dest)
    return True
