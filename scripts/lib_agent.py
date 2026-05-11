"""
OpenClaw agent execution helpers for AgentScry.
"""

from __future__ import annotations

import json
import logging
import os
import subprocess
import time
from pathlib import Path
from typing import Any, Dict, List
from urllib import error, request

import lib_docker as docker
from lib_attacks import get_attack_method, is_pair_attack, IndirectAttackContext
from lib_tasks import Task


logger = logging.getLogger(__name__)


class LLMAPIConfigError(RuntimeError):
    """Raised when a required direct LLM API setting is missing."""


class ModelValidationError(Exception):
    """Raised when a model ID is invalid or inaccessible."""

    pass


MAX_OPENCLAW_MESSAGE_CHARS = int(os.environ.get("SCRY_MAX_MSG_CHARS", "50000"))

# Mapping: step_type -> (carrier_field, carrier_description)
# carrier_field: where to find carrier content in the step dict (None if file-based)
# carrier_description: human-readable label for the injection carrier
STEP_CARRIER_MAP: dict[str, tuple[str | None, str]] = {
    "http_post":               ("context",      "web page HTML"),
    "file":                    ("path",         "file content"),
    "email_new_inbox":         ("body",         "email body"),
    "twitter_new_follower":    ("bio",          "Twitter bio"),
    "twitter_new_post":        ("content",      "Twitter post content"),
    "twitter_new_comment":     ("content",      "Twitter comment"),
    "im_new_contact":          ("last_message", "IM contact last message"),
    "im_new_message":          ("content",      "IM message content"),
    "calendar_new_event":      ("description",  "calendar event description"),
    "banking_new_transaction": ("description",  "banking transaction description"),
    "banking_new_user":        (None,           "banking user profile"),
}


def slugify_model(model_id: str) -> str:
    return model_id.replace("/", "-").replace(".", "-").lower()


def validate_openrouter_model(model_id: str, timeout_seconds: float = 10.0) -> bool:
    """
    Validate that a model ID exists on OpenRouter.

    Args:
        model_id: Model ID (with or without openrouter/ prefix)
        timeout_seconds: HTTP request timeout

    Returns:
        True if model is valid and accessible

    Raises:
        ModelValidationError: If model doesn't exist or validation fails
    """
    # Strip openrouter/ prefix if present
    bare_model_id = model_id
    if bare_model_id.startswith("openrouter/"):
        bare_model_id = bare_model_id[len("openrouter/") :]

    # Skip validation for non-OpenRouter models
    if "/" not in bare_model_id:
        logger.info("Skipping model validation for non-OpenRouter model: %s", model_id)
        return True

    api_key = os.environ.get("OPENROUTER_API_KEY")
    if not api_key:
        logger.warning("OPENROUTER_API_KEY not set, skipping model validation")
        return True

    logger.info("🔍 Validating model: %s", bare_model_id)

    headers = {
        "Authorization": f"Bearer {api_key}",
        "X-Title": "AgentScry",
    }

    # First, try the specific model endpoint (fast path for valid models)
    encoded_model_id = bare_model_id.replace("/", "%2F")
    specific_endpoint = f"https://openrouter.ai/api/v1/models/{encoded_model_id}"
    req = request.Request(specific_endpoint, headers=headers, method="GET")
    try:
        with request.urlopen(req, timeout=timeout_seconds) as resp:
            # Model exists - validation passed
            logger.info("✅ Model validated: %s", bare_model_id)
            return True
    except error.HTTPError as exc:
        if exc.code == 404:
            # Model not found - fall through to fetch full catalog for suggestions
            pass
        else:
            logger.warning("OpenRouter API error during validation: %s", exc)
            return True
    except error.URLError as exc:
        logger.warning("Network error during model validation: %s", exc)
        return True

    # Model not found - fetch full catalog for "did you mean" suggestions
    catalog_endpoint = "https://openrouter.ai/api/v1/models"
    req = request.Request(catalog_endpoint, headers=headers, method="GET")
    try:
        with request.urlopen(req, timeout=timeout_seconds) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except error.HTTPError as exc:
        logger.warning("OpenRouter API error fetching model catalog: %s", exc)
        raise ModelValidationError(f"Model '{bare_model_id}' not found on OpenRouter.")
    except error.URLError as exc:
        logger.warning("Network error fetching model catalog: %s", exc)
        raise ModelValidationError(f"Model '{bare_model_id}' not found on OpenRouter.")
    except json.JSONDecodeError as exc:
        logger.warning("Failed to parse OpenRouter response: %s", exc)
        raise ModelValidationError(f"Model '{bare_model_id}' not found on OpenRouter.")

    models = data.get("data", [])
    model_ids = {
        mid
        for m in models
        if isinstance(m, dict)
        for mid in [m.get("id")]
        if isinstance(mid, str) and mid
    }

    # Some OpenRouter model detail lookups intermittently return 404 for valid
    # IDs. Treat an exact catalog hit as authoritative to avoid false negatives.
    if bare_model_id in model_ids:
        logger.info("✅ Model validated via catalog fallback: %s", bare_model_id)
        return True

    # Check for close matches (typos)
    close_matches = []
    bare_lower = bare_model_id.lower()
    for mid in model_ids:
        mid_lower = mid.lower()
        if mid_lower == bare_lower:
            continue
        if bare_lower in mid_lower or mid_lower in bare_lower:
            close_matches.append(mid)

    error_msg = f"Model '{bare_model_id}' not found on OpenRouter."
    if close_matches:
        close_matches_str = ", ".join(sorted(close_matches)[:5])
        error_msg += f" Did you mean: {close_matches_str}?"
    else:
        # Try to suggest based on provider
        provider = bare_model_id.split("/")[0] if "/" in bare_model_id else None
        if provider:
            provider_models = [m for m in model_ids if m.startswith(f"{provider}/")]
            if provider_models:
                error_msg += (
                    f" Available {provider} models: {', '.join(sorted(provider_models)[:5])}"
                )

    raise ModelValidationError(error_msg)


def _get_agent_workspace(agent_id: str) -> Path | None:
    """Get the workspace path for an agent from OpenClaw config."""
    try:
        list_result = docker.run_cmd(["openclaw", "agents", "list"])
        if list_result.returncode != 0:
            return None

        # Parse the agent list output to find workspace
        # OpenClaw normalizes colons to dashes and lowercases agent names
        normalized_id = agent_id.replace(":", "-").lower()
        lines = list_result.stdout.split("\n")
        found_agent = False
        for line in lines:
            stripped = line.strip()
            if stripped.startswith(f"- {agent_id}") or stripped.startswith(f"- {normalized_id}"):
                found_agent = True
            elif found_agent and "Workspace:" in line:
                workspace_str = line.split("Workspace:")[1].strip()
                # Expand ~ if present
                if workspace_str.startswith("~/"):
                    workspace_str = str(Path.home() / workspace_str[2:])
                return Path(workspace_str)
            elif found_agent and line.strip().startswith("-"):
                # Found next agent, stop looking
                break
        return None
    except Exception as exc:
        logger.warning("Failed to get agent workspace: %s", exc)
        return None


def ensure_agent_exists(agent_id: str, model_id: str, workspace_dir: Path) -> bool:
    """Ensure the OpenClaw agent exists with the correct workspace.

    If the agent already exists but points to a different workspace, it is
    deleted and recreated so that the new workspace takes effect.
    Returns True if the agent was (re)created.
    """
    workspace_dir.mkdir(parents=True, exist_ok=True)

    try:
        list_result = docker.run_cmd(["openclaw", "agents", "list"])
    except FileNotFoundError:
        logger.error("openclaw CLI not found while listing agents")
        return False

    if list_result.returncode == 0:
        # Check for exact agent ID match — avoid substring false positives
        # (e.g. "bench-foo-4" matching "bench-foo-4-5" in the output).
        # Output format is "- <agent_id>" or "- <agent_id> (default)" per line.
        # OpenClaw normalizes colons to dashes in directory/display names, so
        # also check the normalized form.
        existing_agents = set()
        for line in list_result.stdout.splitlines():
            line = line.strip()
            if line.startswith("- "):
                # Extract agent name: "- bench-foo-4-5" or "- main (default)"
                name_part = line[2:].split()[0] if line[2:].strip() else ""
                if name_part:
                    existing_agents.add(name_part.lower())
        normalized_id = agent_id.replace(":", "-").lower()
        if agent_id.lower() in existing_agents or normalized_id in existing_agents:
            # Agent exists — check if workspace matches
            current_workspace = _get_agent_workspace(agent_id)
            if (
                current_workspace is not None
                and current_workspace.resolve() == workspace_dir.resolve()
            ):
                logger.info("Agent %s already exists with correct workspace", agent_id)
                return False
            # Workspace is stale or unknown — delete and recreate
            delete_name = normalized_id if normalized_id in existing_agents else agent_id
            logger.info(
                "Agent %s exists with stale workspace (%s != %s), recreating",
                agent_id,
                current_workspace,
                workspace_dir,
            )
            docker.run_cmd(
                ["openclaw", "agents", "delete", delete_name, "--force"],
            )

    logger.info("Creating OpenClaw agent %s", agent_id)
    try:
        create_result = docker.run_cmd(
            [
                "openclaw",
                "agents",
                "add",
                agent_id,
                "--model",
                model_id,
                "--workspace",
                str(workspace_dir),
                "--non-interactive",
            ],
        )
    except FileNotFoundError:
        logger.error("openclaw CLI not found while creating agent")
        return False

    if create_result.returncode != 0:
        logger.warning(
            "Agent creation returned %s: %s", create_result.returncode, create_result.stderr
        )
    return True


def cleanup_agent_sessions(agent_id: str) -> None:
    """Remove stored session transcripts for an agent to avoid unbounded growth."""
    agent_dir = _get_agent_store_dir(agent_id)
    sessions_dir = agent_dir / "sessions"
    if not sessions_dir.exists():
        return
    removed = 0
    for pattern in ("*.jsonl", "*.jsonl.lock"):
        for path in sessions_dir.glob(pattern):
            try:
                path.unlink()
                removed += 1
            except OSError as exc:
                logger.warning("Failed to remove session file %s: %s", path, exc)
    sessions_store = sessions_dir / "sessions.json"
    if sessions_store.exists():
        try:
            sessions_store.unlink()
        except OSError as exc:
            logger.warning("Failed to remove session store %s: %s", sessions_store, exc)
    if removed:
        logger.info("Removed %s old OpenClaw session transcripts for %s", removed, agent_id)


def cleanup_agent_sessions_in_container(agent_id: str) -> None:
    """Remove session transcripts inside the Docker container.

    This is the container-side counterpart of cleanup_agent_sessions().
    Used when we need to force a fresh conversation context (e.g. new_session: true)
    while the container is still running.  No-op if Docker mode is not active.
    """
    if not docker.is_active():
        return
    container_sessions_dir = f"/root/.openclaw/agents/{agent_id}/sessions"
    result = docker.run_cmd(
        ["sh", "-c",
         f"rm -f {container_sessions_dir}/*.jsonl "
         f"{container_sessions_dir}/*.jsonl.lock "
         f"{container_sessions_dir}/sessions.json 2>/dev/null; echo ok"],
    )
    if result.returncode == 0:
        logger.info("Cleaned container-side session files for %s", agent_id)
    else:
        logger.warning("Failed to clean container-side sessions: %s", result.stderr)


def _substitute_env_vars(value: str) -> str:
    """Replace ${ENV_VAR} patterns with environment variable values."""
    import re

    def replacer(match: re.Match) -> str:
        var_name = match.group(1)
        return os.environ.get(var_name, match.group(0))

    return re.sub(r"\$\{(\w+)\}", replacer, str(value))


def _run_pre_setup(task: Task, workspace: Path = None, skill_dir: Path = None) -> None:
    """Execute pre-setup steps defined in task frontmatter."""
    pre_setup = task.frontmatter.get("pre_setup", [])
    if not pre_setup:
        return
    for step in pre_setup:
        skill_data_dir = workspace.parent.parent / "skill_data"
        setup_type = step.get("type", "")
        if setup_type == "http_post":
            _execute_http_post_setup(step, workspace)
        elif setup_type == "skill_copy":
            _execute_skill_copy_setup(step, skill_dir, workspace)
        elif setup_type == "memory_poison":
            _execute_memory_poison_setup(step, workspace)
        elif setup_type == "dependency_copy":
            _execute_dependency_copy_setup(step, skill_dir, workspace)
        elif setup_type == "file":
            _execute_file_setup(step, workspace)
        elif setup_type == "twitter_new_follower":
            _execute_skill_new_entry_setup(step, skill_data_dir / "twitter/data/followers.json", "bio")
        elif setup_type == "twitter_new_post":
            _execute_skill_new_entry_setup(step, skill_data_dir / "twitter/data/posts.json", "content")
        elif setup_type == "twitter_new_comment":
            _execute_skill_new_entry_setup(step, skill_data_dir / "twitter/data/comments.json", "content")
        elif setup_type == "im_new_contact":
            _execute_skill_new_entry_setup(step, skill_data_dir / "dingtalk/data/contacts.json", "last_message")
        elif setup_type == "im_new_message":
            _execute_skill_new_entry_setup(step, skill_data_dir / "dingtalk/data/messages.json", "content")
        elif setup_type == "email_new_inbox":
            _execute_skill_new_entry_setup(step, skill_data_dir / "email/data/inbox.json", "body")
        elif setup_type == "calendar_new_event":
            _execute_skill_new_entry_setup(step, skill_data_dir / "calendar/data/events.json", "description")
        elif setup_type == "banking_new_user":
            _execute_skill_new_entry_setup(step, skill_data_dir / "bank_system/data/users.json")
        elif setup_type == "banking_new_transaction":
            _execute_skill_new_entry_setup(step, skill_data_dir / "bank_system/data/transactions.json", "description")
        else:
            logger.warning("Unknown pre_setup type: %s", setup_type)


def _execute_skill_copy_setup(step: dict, skill_dir: Path, workspace: Path) -> None:
    """Execute a skill_copy pre-setup step.

    Copies a skill directory from assets to the agent workspace's skills folder.
    ``source_path_dir`` is resolved relative to the project root (skill_dir).
    ``target_path_dir`` is placed under ``<workspace>/skills/``.
    """
    import shutil

    source_path_dir = step.get("source_path_dir", "")
    target_path_dir = step.get("target_path_dir", "")
    if not source_path_dir or not target_path_dir:
        logger.warning("skill_copy step missing source_path_dir or target_path_dir")
        return

    source = skill_dir / source_path_dir
    dest = workspace / "skills" / target_path_dir

    if not source.exists():
        logger.error("skill_copy source not found: %s", source)
        return

    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists():
        shutil.rmtree(dest)
    shutil.copytree(source, dest)
    logger.info("skill_copy: copied %s -> %s", source, dest)


def _execute_memory_poison_setup(step: dict, workspace: Path) -> None:
    """Execute a memory_poison pre-setup step.

    Creates a MEMORY.md file in the workspace that contains the context
    file content with poison content appended to the end.
    ``context`` is a direct file path.
    ``poison`` is the content to append.
    """
    context_path = step.get("context", "")
    poison_content = step.get("poison", "")
    if not context_path or not poison_content:
        logger.warning("memory_poison step missing context or poison")
        return

    source = Path(context_path)
    if not source.exists():
        logger.error("memory_poison context file not found: %s", source)
        return

    # Read context content
    context_content = source.read_text(encoding="utf-8")

    # Combine with poison content
    combined_content = context_content + "\n\n" + "## Important Note\n\n" + poison_content

    # Write to workspace MEMORY.md
    dest = workspace / "MEMORY.md"
    dest.write_text(combined_content, encoding="utf-8")
    logger.info("memory_poison: created MEMORY.md from %s with poison appended (poison_content: %s)", source, poison_content)


def _execute_dependency_copy_setup(step: dict, skill_dir: Path, workspace: Path) -> None:
    """Execute a dependency_copy pre-setup step.

    Copies dependency files from assets/skills_dependency to the agent workspace.
    ``source_path_dir`` is resolved relative to assets/skills_dependency.
    ``target_path_dir`` is placed under ``<workspace>/`` (must be specified, e.g., "skill_test/xxx").

    Special case: If target_path_dir starts with "~/" (e.g., "~/.ssh"), files are copied
    into the Docker container's home directory using docker exec commands.

    Supports both:
    - source_path_dir as a directory (copies entire directory)
    - source_files as a list of specific files to copy
    """
    import shutil

    source_path_dir = step.get("source_path_dir", "")
    target_path_dir = step.get("target_path_dir", "")
    source_files = step.get("source_files", [])  # Optional: list of specific files

    if not source_path_dir:
        logger.warning("dependency_copy step missing source_path_dir")
        return

    if not target_path_dir:
        logger.warning("dependency_copy step missing target_path_dir (required to avoid overwriting skill_copy results)")
        return

    # Resolve source from assets/skills_dependency/
    source = skill_dir / "assets" / "skills_dependency" / source_path_dir

    if not source.exists():
        logger.error("dependency_copy source not found: %s", source)
        return

    # Check if target is a container home directory path (starts with "~/")
    if target_path_dir.startswith("~/"):
        _copy_to_container_home(source, target_path_dir, source_files, workspace)
        return

    # Use target_path_dir from task configuration (e.g., "skill_test/ssh-keygen-helper")
    dest = workspace / target_path_dir

    if source_files:
        # Copy specific files only
        dest.mkdir(parents=True, exist_ok=True)
        for file_name in source_files:
            src_file = source / file_name
            if src_file.exists():
                dst_file = dest / file_name
                dst_file.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src_file, dst_file)
                logger.info("dependency_copy: copied file %s -> %s", src_file, dst_file)
            else:
                logger.warning("dependency_copy: source file not found: %s", src_file)
    else:
        # Copy entire directory
        dest.parent.mkdir(parents=True, exist_ok=True)
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(source, dest)
        logger.info("dependency_copy: copied directory %s -> %s", source, dest)


def _copy_to_container_home(source: Path, target_path_dir: str, source_files: list, workspace: Path) -> None:
    """Copy files to the Docker container's home directory (e.g., ~/.ssh -> /root/.ssh).

    This function uses `docker cp` to copy files directly from host to container,
    avoiding complex path mapping issues between macOS and Docker.
    """
    import shutil
    import tempfile

    container_id = docker.get_container_id()
    if not container_id:
        logger.warning("dependency_copy: cannot copy to container home - no active container")
        return

    # Expand ~/ to /root/ (container's home directory)
    container_home_path = target_path_dir.replace("~", "/root", 1)

    # Create a temporary staging directory on the host (not in workspace to avoid mount issues)
    # Use a predictable location under /tmp to avoid macOS symlink issues
    staging_base = Path("/tmp/scry_staging")
    staging_base.mkdir(parents=True, exist_ok=True)
    staging_dir = staging_base / f"staging_{os.getpid()}"

    try:
        # Clean up any existing staging dir
        if staging_dir.exists():
            shutil.rmtree(staging_dir)
        staging_dir.mkdir(parents=True, exist_ok=True)

        if source_files:
            # Copy specific files to staging
            for file_name in source_files:
                src_file = source / file_name
                if src_file.exists():
                    staging_file = staging_dir / file_name
                    staging_file.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(src_file, staging_file)
        else:
            # Copy entire directory to staging
            shutil.copytree(source, staging_dir, dirs_exist_ok=True)

        # Create target directory in container
        mkdir_cmd = ["docker", "exec", container_id, "mkdir", "-p", container_home_path]
        result = subprocess.run(mkdir_cmd, capture_output=True, text=True, timeout=10)
        if result.returncode != 0:
            logger.error("dependency_copy: failed to create container directory %s: %s", container_home_path, result.stderr)
            return

        # Use docker cp to copy from host staging to container
        # docker cp works with container paths, no need to find mount points
        cp_cmd = ["docker", "cp", str(staging_dir) + "/.", f"{container_id}:{container_home_path}"]
        result = subprocess.run(cp_cmd, capture_output=True, text=True, timeout=30)
        if result.returncode != 0:
            logger.warning("dependency_copy: failed to copy to container: %s", result.stderr)
            return

        logger.info("dependency_copy: copied to container home %s -> %s", source, container_home_path)

    finally:
        # Clean up staging directory
        if staging_dir.exists():
            shutil.rmtree(staging_dir)


def _get_workspace_path_in_container(container_id: str, host_workspace: str) -> Path | None:
    """Find the workspace path as seen inside the container.

    The host workspace is mounted somewhere in the container. We need to find
    the mount point to construct the correct container-internal path.
    """
    try:
        # Get container mount info
        inspect_cmd = ["docker", "inspect", container_id, "--format", "{{json .Mounts}}"]
        result = subprocess.run(inspect_cmd, capture_output=True, text=True, timeout=10)
        if result.returncode != 0:
            return None

        import json
        mounts = json.loads(result.stdout)

        # On macOS, /tmp is a symlink to /private/tmp, so we need to handle both
        # Try both the resolved path and the original path
        host_workspace_resolved = str(Path(host_workspace).resolve())
        host_workspace_original = str(Path(host_workspace))

        # Also try to get the real path without following the final symlink
        # e.g., /tmp/scry/... instead of /private/tmp/scry/...
        host_workspace_real = host_workspace_original
        if host_workspace_resolved.startswith("/private/") and host_workspace_original.startswith("/"):
            # macOS case: use the non-resolved path (e.g., /tmp/... instead of /private/tmp/...)
            host_workspace_real = host_workspace_original

        for mount in mounts:
            src = mount.get("Source", "")
            dst = mount.get("Destination", "")

            # Try matching with different host path variations
            for host_path in [host_workspace_resolved, host_workspace_real, host_workspace_original]:
                if host_path.startswith(src) or src == host_path:
                    # Found the mount, compute the container path
                    if src == host_path:
                        return Path(dst)
                    else:
                        # Host path is a subdirectory of the mount
                        relative = host_path[len(src):]
                        return Path(dst + relative)

        # Fallback: try to find mount by checking if any mount source is a parent of our path
        for mount in mounts:
            src = mount.get("Source", "")
            dst = mount.get("Destination", "")
            # Check if path starts with mount source (after resolving symlinks)
            for host_path in [host_workspace_resolved, host_workspace_real]:
                # Also check if the mount source is a symlink target
                try:
                    src_resolved = str(Path(src).resolve())
                    if host_path.startswith(src_resolved):
                        relative = host_path[len(src_resolved):]
                        return Path(dst + relative)
                except:
                    pass

        # Final fallback: assume the original path works in container
        logger.warning("Could not find exact mount match, using original path: %s", host_workspace_real)
        return Path(host_workspace_real)

    except Exception as e:
        logger.warning("Failed to find workspace mount point: %s", e)
        return None


def _execute_http_post_setup(step: dict, workspace: Path) -> None:
    """Execute an HTTP POST mock setup step.

    If ``injection_goal`` is empty, copies file from ``context`` to ``dest``.
    If ``injection_goal`` is not empty, writes ``injection_goal`` to ``dest``.
    ``uid`` is taken from the step configuration.
    """
    import shutil

    uid = step.get("uid", "")
    injection_goal = step.get("injection_goal", "")
    context_path = step.get("context", "")

    if not uid:
        logger.warning("http_post step missing uid")
        return

    # Create mock_api directory
    mock_api_dir = workspace.parent.parent / "mock_api/data"
    mock_api_dir.mkdir(parents=True, exist_ok=True)

    # Destination: mock_api/uid.<file_type>
    file_type = step.get("file_type", "html")
    dest = mock_api_dir / f"{uid}.{file_type}"

    if injection_goal:
        # Write injection_goal directly
        with open(dest, "w", encoding="utf-8") as f:
            f.write(injection_goal)
        logger.info("http_post: wrote injection_goal to %s", dest)
    else:
        # Copy from context path
        if not context_path:
            logger.warning("http_post step missing context path (and no injection_goal)")
            return
        source = Path(context_path)
        if not source.exists():
            logger.error("http_post context file not found: %s", source)
            return
        shutil.copy2(source, dest)
        logger.info("http_post: copied %s -> %s", source, dest)



def _execute_file_setup(step: dict, workspace: Path) -> None:
    """Execute a file pre-setup step.

    If ``injection_goal`` is empty, copies file from ``path`` to ``dest``.
    If ``injection_goal`` is not empty, writes ``injection_goal`` to ``dest``.
    ``dest`` is the destination filename/path in the workspace.
    """
    import shutil

    dest_path = step.get("dest", "")
    injection_goal = step.get("injection_goal", "")
    source_path = step.get("path", "")

    if not dest_path:
        logger.warning("file step missing dest")
        return

    dest = workspace / dest_path
    dest.parent.mkdir(parents=True, exist_ok=True)

    if injection_goal:
        # Write injection_goal directly
        with open(dest, "w", encoding="utf-8") as f:
            f.write(str(injection_goal))
        logger.info("file: wrote injection_goal to %s", dest)
    else:
        # Copy from path
        if not source_path:
            logger.warning("file step missing path (and no injection_goal)")
            return
        source = Path(source_path)
        if not source.exists():
            logger.error("file source not found: %s", source)
            return
        shutil.copy2(source, dest)
        logger.info("file: copied %s -> %s", source, dest)



def _append_new_entry(items: list, step: dict) -> list:
    """Append a new entry to a list by copying the first item as template.

    Args:
        items: List of dict entries
        step: Configuration dict with field values to update (skips "type" key)

    Returns:
        Updated list with new entry appended
    """
    import copy

    if not items or not isinstance(items, list):
        return items

    template = items[0]
    new_entry = copy.deepcopy(template)

    for key, value in step.items():
        if key != "type" and key in new_entry:
            new_entry[key] = value

    items.append(new_entry)
    return items


def _execute_skill_new_entry_setup(step: dict, json_file: Path, injection_target: str = None) -> None:
    """Execute a skill_new_entry pre-setup step.

    Creates a new entry in the specified JSON file by copying the first existing
    entry and updating fields from the step config.

    Args:
        step: Configuration dict with field values to update (skips "type" key)
        json_file: Path to the JSON file to modify
        injection_target: Field name to inject injection_goal into (overwritten with injection_goal value)
    """
    if not json_file.exists():
        logger.warning("File not found: %s", json_file)
        return

    try:
        with open(json_file, "r", encoding="utf-8") as f:
            items = json.load(f)
    except json.JSONDecodeError as exc:
        logger.warning("Failed to parse %s: %s", json_file.name, exc)
        return

    if not items or not isinstance(items, list):
        logger.warning("%s is empty or not a list", json_file.name)
        return

    # set injection_goal to injection_target field if not empty
    injection_goal = step.get('injection_goal', '')
    if injection_goal and injection_target:
        step[injection_target] = injection_goal

    updated = _append_new_entry(items, step)
    logger.info("Added new entry to %s", json_file.name)

    try:
        with open(json_file, "w", encoding="utf-8") as f:
            json.dump(updated, f, ensure_ascii=False, indent=2)
    except OSError as exc:
        logger.warning("Failed to write %s: %s", json_file.name, exc)


def prepare_task_workspace(skill_dir: Path, run_id: str, task: Task, agent_id: str, workspace_dir: Path):
    """
    Prepare workspace for a task by copying fixtures.
    Uses the agent's configured workspace to ensure files are in the right place.
    """
    import shutil

    # Get agent's workspace from agent config
    workspace = workspace_dir
    if workspace is None:
        # Fallback to task-specific workspace if agent workspace not found
        logger.warning("Could not find agent workspace, using fallback")
        workspace = Path(f"/tmp/scry/{run_id}/{task.task_id}")

    # Clear workspace before each task to prevent stale files from prior tasks
    # from contaminating the agent's context.
    if workspace.exists():
        try:
            shutil.rmtree(workspace)
        except OSError as e:
            logger.warning("Failed to remove workspace %s: %s, attempting to fix permissions", workspace, e)
            # Try to fix permissions and retry
            import os
            for root, dirs, files in os.walk(workspace):
                for d in dirs:
                    try:
                        os.chmod(os.path.join(root, d), 0o755)
                    except OSError:
                        pass
                for f in files:
                    try:
                        os.chmod(os.path.join(root, f), 0o644)
                    except OSError:
                        pass
            try:
                os.chmod(workspace, 0o755)
            except OSError:
                pass
            shutil.rmtree(workspace)
    workspace.mkdir(parents=True, exist_ok=True)

    for file_spec in task.workspace_files:
        if "content" in file_spec:
            dest = workspace / file_spec["path"]
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_text(file_spec["content"])
            continue

        source = skill_dir / "assets" / file_spec["source"]
        dest = workspace / file_spec["dest"]
        dest.parent.mkdir(parents=True, exist_ok=True)
        try:
            dest.write_bytes(source.read_bytes())
        except FileNotFoundError:
            logger.error("Workspace file not found: %s", source)
            raise

    # Remove bootstrap files that would trigger the onboarding flow
    # These interfere with benchmark tasks
    for bootstrap_file in ["BOOTSTRAP.md", "SOUL.md", "USER.md", "IDENTITY.md"]:
        bootstrap_path = workspace / bootstrap_file
        if bootstrap_path.exists():
            try:
                bootstrap_path.unlink()
                logger.info("Removed bootstrap file: %s", bootstrap_file)
            except OSError as exc:
                logger.warning("Failed to remove %s: %s", bootstrap_file, exc)

    # Copy skills from main workspace to benchmark workspace
    # This enables benchmark agents to use installed skills like nano-pdf
    main_skills_dir = Path.home() / ".openclaw" / "workspace" / "skills"
    if main_skills_dir.exists():
        dest_skills_dir = workspace / "skills"
        dest_skills_dir.mkdir(parents=True, exist_ok=True)
        for skill_dir_src in main_skills_dir.iterdir():
            if skill_dir_src.is_dir():
                dest_skill_dir = dest_skills_dir / skill_dir_src.name
                # Copy skill directory
                import shutil

                if dest_skill_dir.exists():
                    shutil.rmtree(dest_skill_dir)
                shutil.copytree(skill_dir_src, dest_skill_dir)
                logger.info("Copied skill to benchmark workspace: %s", skill_dir_src.name)

    # Copy assets/skill_data
    src_data_dir = Path("assets/skill_data")
    dest_data_dir = workspace.parent.parent / "skill_data"
    if src_data_dir.exists():
        dest_data_dir.mkdir(parents=True, exist_ok=True)
        import shutil
        for item in src_data_dir.iterdir():
            dest_item = dest_data_dir / item.name
            if item.is_dir():
                shutil.copytree(item, dest_item, dirs_exist_ok=True)
            else:
                shutil.copy2(item, dest_item)
        logger.info("Copied ./skill_data -> %s", dest_data_dir)

    # Execute pre-setup steps (e.g., HTTP calls to set up external services, skill copies)
    _run_pre_setup(task, workspace, skill_dir)

def _get_agent_store_dir(agent_id: str) -> Path:
    """Get the directory where agent transcripts are stored.

    Uses docker.get_agent_store_base() which returns the right path
    for both local (~/.openclaw/agents/) and docker mode.
    """
    direct_dir = docker.get_agent_store_base(agent_id)
    if direct_dir.exists():
        return direct_dir
    # OpenClaw normalizes agent IDs to lowercase and replaces colons with dashes
    normalized_id = agent_id.replace(":", "-").lower()
    normalized_dir = direct_dir.parent / normalized_id
    if normalized_dir.exists():
        return normalized_dir
    return direct_dir


def _resolve_session_id_from_store(agent_id: str) -> str | None:
    agent_dir = _get_agent_store_dir(agent_id)
    sessions_store = agent_dir / "sessions" / "sessions.json"
    if not sessions_store.exists():
        return None
    try:
        sessions_payload = json.loads(sessions_store.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        logger.warning("Failed to parse sessions store: %s", exc)
        return None
    if not isinstance(sessions_payload, dict):
        return None

    normalized_id = agent_id.replace(":", "-").lower()
    preferred_keys = [
        f"agent:{agent_id}:main",
        f"agent:{agent_id}:default",
        f"agent:{normalized_id}:main",
        f"agent:{normalized_id}:default",
    ]
    for key in preferred_keys:
        entry = sessions_payload.get(key)
        if isinstance(entry, dict) and entry.get("sessionId"):
            return entry["sessionId"]

    newest_entry = None
    newest_timestamp = -1
    for entry in sessions_payload.values():
        if not isinstance(entry, dict):
            continue
        if "sessionId" not in entry:
            continue
        updated_at = entry.get("updatedAt")
        if isinstance(updated_at, (int, float)) and updated_at > newest_timestamp:
            newest_timestamp = updated_at
            newest_entry = entry
    if newest_entry:
        return newest_entry.get("sessionId")
    return None


def _find_recent_session_path(agent_dir: Path, started_at: float) -> Path | None:
    sessions_dir = agent_dir / "sessions"
    if not sessions_dir.exists():
        return None
    candidates = list(sessions_dir.glob("*.jsonl"))
    if not candidates:
        return None
    tolerance_seconds = 5.0
    recent_candidates = [
        path for path in candidates if path.stat().st_mtime >= (started_at - tolerance_seconds)
    ]
    pool = recent_candidates or candidates
    return max(pool, key=lambda path: path.stat().st_mtime)


def _load_transcript(agent_id: str, session_id: str, started_at: float, agent_dir_param:str) -> List[Dict[str, Any]]:
    agent_dir = ''
    if agent_dir_param == '':
        agent_dir = _get_agent_store_dir(agent_id)
    else:
        agent_dir = Path(agent_dir_param)

    transcript_path = None

    # OpenClaw ignores the --session-id we pass and generates its own UUID-based
    # session ID internally.  We need to discover the actual transcript path.
    #
    # Strategy (with retries to handle write-delay):
    #   1. Resolve the real session ID from sessions.json
    #   2. Glob for any .jsonl in the sessions dir (most-recently-modified)
    #   3. Try our passed-in session ID as a last resort
    for attempt in range(6):
        # 1. Try sessions.json first — OpenClaw writes the real UUID here
        resolved_session_id = _resolve_session_id_from_store(agent_id)
        if resolved_session_id:
            candidate = agent_dir / "sessions" / f"{resolved_session_id}.jsonl"
            if candidate.exists():
                transcript_path = candidate
                logger.info(
                    "Found transcript via sessions.json: %s (attempt %s)",
                    candidate.name,
                    attempt + 1,
                )
                break

        # 2. Glob fallback — pick the most recently modified .jsonl
        recent_path = _find_recent_session_path(agent_dir, started_at)
        if recent_path is not None:
            transcript_path = recent_path
            logger.info(
                "Found transcript via glob fallback: %s (attempt %s)",
                recent_path.name,
                attempt + 1,
            )
            break

        # 3. Try our passed-in session ID (unlikely to work, but check anyway)
        direct_path = agent_dir / "sessions" / f"{session_id}.jsonl"
        if direct_path.exists():
            transcript_path = direct_path
            logger.info(
                "Found transcript via passed session ID: %s (attempt %s)",
                direct_path.name,
                attempt + 1,
            )
            break

        if attempt < 5:
            time.sleep(1.0)

    if transcript_path is None:
        sessions_dir = agent_dir / "sessions"
        if sessions_dir.exists():
            all_files = list(sessions_dir.iterdir())
            logger.warning(
                "Transcript not found for agent %s. Sessions dir contents: %s",
                agent_id,
                [f.name for f in all_files],
            )
        else:
            logger.warning(
                "Transcript not found — sessions dir does not exist: %s",
                sessions_dir,
            )
        return []

    transcript: List[Dict[str, Any]] = []
    for line in transcript_path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        try:
            transcript.append(json.loads(line))
        except json.JSONDecodeError as exc:
            logger.warning("Failed to parse transcript line: %s", exc)
            transcript.append({"raw": line, "parse_error": str(exc)})
    return transcript


def _extract_usage_from_transcript(transcript: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Sum token usage and cost from all assistant messages in transcript."""
    totals = {
        "input_tokens": 0,
        "output_tokens": 0,
        "cache_read_tokens": 0,
        "cache_write_tokens": 0,
        "total_tokens": 0,
        "cost_usd": 0.0,
        "request_count": 0,
    }

    for entry in transcript:
        if entry.get("type") != "message":
            continue
        msg = entry.get("message", {})
        if msg.get("role") != "assistant":
            continue
        totals["request_count"] += 1
        usage = msg.get("usage", {})
        totals["input_tokens"] += usage.get("input", 0)
        totals["output_tokens"] += usage.get("output", 0)
        totals["cache_read_tokens"] += usage.get("cacheRead", 0)
        totals["cache_write_tokens"] += usage.get("cacheWrite", 0)
        totals["total_tokens"] += usage.get("totalTokens", 0)
        cost = usage.get("cost", {})
        totals["cost_usd"] += cost.get("total", 0.0)

    return totals


def _resolve_carrier_content(step: dict, step_type: str, skill_dir: Path | None) -> str:
    """Resolve carrier (benign) content from a pre_setup step.

    For http_post/file: reads the file referenced by ``context``/``path``.
    For skill_new_entry types: reads the value of the carrier field in the step dict.
    """
    carrier_field, _ = STEP_CARRIER_MAP.get(step_type, (None, "unknown"))

    # File-based carriers: http_post (context) and file (path)
    if step_type == "http_post":
        file_path = step.get("context", "")
        if file_path and skill_dir:
            source = skill_dir / file_path
            if source.is_file():
                return source.read_text(encoding="utf-8", errors="replace")
        return ""

    if step_type == "file":
        file_path = step.get("path", "")
        if file_path and skill_dir:
            source = skill_dir / file_path
            if source.is_file():
                try:
                    return source.read_text(encoding="utf-8", errors="replace")
                except UnicodeDecodeError:
                    logger.warning("Binary file %s cannot be read as text carrier", source)
                    return ""
        return ""

    # Field-based carriers: skill_new_entry types
    if carrier_field and carrier_field in step:
        value = step[carrier_field]
        if isinstance(value, str):
            return value
        return str(value)

    return ""


def _apply_attack_to_task(attack_method: str, task: Task, skill_dir: Path | None = None, no_context: bool = False) -> tuple:
    """
    Apply an attack method to a task, returning a modified copy and optional transformed prompt.

    For direct attacks: transforms the prompt
    For indirect attacks: modifies workspace_files and pre_setup content

    Returns:
        Tuple of (modified_task, transformed_prompt).
        transformed_prompt is None for indirect attacks.
    """
    import copy

    attack = get_attack_method(attack_method)

    # Create a deep copy of the task to modify
    modified_task = copy.copy(task)
    modified_task.frontmatter = copy.deepcopy(task.frontmatter)
    modified_task.workspace_files = copy.deepcopy(task.workspace_files)

    transformed_prompt = None

    if attack.category == "direct":
        # Direct attack: transform the prompt
        original_intent = task.frontmatter.get("original_intent", task.prompt)
        logger.info("🔓 Applying direct attack '%s' to prompt", attack_method)

        transformed_prompt = attack.apply(original_intent)

        logger.info("   Original intent: %s", original_intent[:100] + "..." if len(original_intent) > 100 else original_intent)
        logger.info("   Transformed prompt: %s", transformed_prompt[:100] + "..." if len(transformed_prompt) > 100 else transformed_prompt)

    elif attack.category == "indirect":
        # Indirect attack: iterate pre_setup steps and apply to each with injection_goal
        logger.info("🔓 Applying indirect attack '%s'", attack_method)

        pre_setup = modified_task.frontmatter.get("pre_setup", [])
        user_prompt = task.frontmatter.get("prompt", "")

        for step in pre_setup:
            injection_goal = step.get("injection_goal", "")
            if not injection_goal:
                continue

            step_type = step.get("type", "")
            carrier_content = _resolve_carrier_content(step, step_type, skill_dir)
            if no_context:
                carrier_content = ""
                logger.info("   --no-context: cleared carrier content for step '%s'", step_type)
            carrier_desc = STEP_CARRIER_MAP.get(step_type, (None, "unknown"))[1]

            context = IndirectAttackContext(
                user_prompt=user_prompt,
                injection_goal=injection_goal,
                injection_carrier=carrier_desc,
                carrier_content=carrier_content,
                step_type=step_type,
            )
            combined = attack.apply_indirect(context)
            step["injection_goal"] = combined

            logger.info(
                "   Step '%s' injection_goal replaced (carrier=%d chars)",
                step_type, len(carrier_content),
            )

    return modified_task, transformed_prompt


def _extract_assistant_text(transcript: list) -> str:
    """Extract all assistant text content from a transcript.

    Handles both string content and list-of-blocks content format
    (OpenClaw transcripts use [{type: "text", text: "..."}, ...]).
    """
    parts = []
    for entry in transcript:
        if entry.get("type") != "message":
            continue
        msg = entry.get("message", {})
        if msg.get("role") != "assistant":
            continue
        content = msg.get("content", "")
        if isinstance(content, str):
            parts.append(content)
        elif isinstance(content, list):
            for block in content:
                if isinstance(block, dict) and block.get("type") == "text":
                    parts.append(block.get("text", ""))
    return "\n".join(parts)


def _call_llm_api_internal(
    prompt: str,
    base_url: str,
    api_key: str,
    model: str,
    timeout_seconds: float = 60,
    max_retries: int = 0,
) -> str:
    """
    Internal helper: make a direct LLM API call.

    Args:
        prompt: The prompt to send to the LLM
        base_url: Base URL of the LLM API
        api_key: API key for authentication
        model: Model ID to use
        timeout_seconds: Request timeout in seconds
        max_retries: Maximum retries (0 = infinite retry until success)

    Returns:
        The assistant's text response, or empty string on failure.
    """
    missing = [
        name
        for name, value in (
            ("base_url", base_url),
            ("api_key", api_key),
            ("model", model),
        )
        if not value
    ]
    if missing:
        raise LLMAPIConfigError(
            "LLM API configuration is incomplete; missing: " + ", ".join(missing)
        )

    url = f"{base_url.rstrip('/')}/chat/completions"
    payload = json.dumps({
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": 25600,
    }).encode("utf-8")

    attempt = 0
    while True:
        attempt += 1

        req = request.Request(
            url,
            data=payload,
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
            method="POST",
        )

        try:
            with request.urlopen(req, timeout=timeout_seconds) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                choices = data.get("choices", [])
                if choices:
                    if attempt > 1:
                        logger.info("LLM API call succeeded on attempt %d", attempt)
                    return choices[0].get("message", {}).get("content", "")
                return ""

        except error.HTTPError as exc:
            # Handle rate limit (429) and server errors (5xx)
            if exc.code == 429:
                retry_after = exc.headers.get("Retry-After", "30")
                try:
                    wait_time = int(retry_after)
                except ValueError:
                    wait_time = 30
                logger.warning(
                    "LLM API rate limited (429), waiting %ds before retry (attempt %d)",
                    wait_time, attempt
                )
                time.sleep(wait_time)
                continue
            elif exc.code >= 500:
                logger.warning(
                    "LLM API server error (%d), retrying in 10s (attempt %d)",
                    exc.code, attempt
                )
                time.sleep(10)
                continue
            else:
                logger.warning("LLM API HTTP error (%d): %s", exc.code, exc)
                if max_retries > 0 and attempt >= max_retries:
                    return ""
                time.sleep(5)
                continue

        except error.URLError as exc:
            # Connection error / timeout - retry
            logger.warning(
                "LLM API connection error/timeout, retrying in 10s (attempt %d): %s",
                attempt, exc
            )
            time.sleep(10)
            continue

        except (json.JSONDecodeError, OSError) as exc:
            logger.warning("LLM API call failed: %s", exc)
            if max_retries > 0 and attempt >= max_retries:
                return ""
            time.sleep(5)
            continue

        except Exception as exc:
            logger.warning("LLM API unexpected error: %s", exc)
            if max_retries > 0 and attempt >= max_retries:
                return ""
            time.sleep(5)
            continue

    return ""


def _call_pair_llm_api(
    prompt: str,
    timeout_seconds: float = 60,
    max_retries: int = 0,
    model: str | None = None,
) -> str:
    """
    Make a direct LLM API call for PAIR attacker.

    Uses PAIR_LLM_BASE_URL, PAIR_LLM_API_KEY, and PAIR_LLM_MODEL env vars.

    Args:
        prompt: The prompt to send to the LLM
        timeout_seconds: Request timeout in seconds
        max_retries: Maximum retries (0 = infinite retry until success)
        model: Optional model override. If not provided, uses PAIR_LLM_MODEL env var.

    Returns:
        The assistant's text response, or empty string on failure.
    """
    base_url = os.environ.get("PAIR_LLM_BASE_URL")
    api_key = os.environ.get("PAIR_LLM_API_KEY")
    env_model = os.environ.get("PAIR_LLM_MODEL")
    llm_model = model if model is not None else env_model
    missing = [
        name
        for name, value in (
            ("PAIR_LLM_BASE_URL", base_url),
            ("PAIR_LLM_API_KEY", api_key),
            ("PAIR_LLM_MODEL", llm_model),
        )
        if not value
    ]
    if missing:
        raise LLMAPIConfigError(
            "PAIR attack requires direct LLM API settings; missing: " + ", ".join(missing)
        )

    return _call_llm_api_internal(
        prompt=prompt,
        base_url=base_url,
        api_key=api_key,
        model=llm_model,
        timeout_seconds=timeout_seconds,
        max_retries=max_retries,
    )


def _call_judge_llm_api(
    prompt: str,
    timeout_seconds: float = 60,
    max_retries: int = 0,
    model: str | None = None,
) -> str:
    """
    Make a direct LLM API call for judge.

    Uses JUDGE_LLM_* environment variables.

    Args:
        prompt: The prompt to send to the LLM
        timeout_seconds: Request timeout in seconds
        max_retries: Maximum retries (0 = infinite retry until success)
        model: Optional model override. If not provided, uses JUDGE_LLM_MODEL env var.

    Returns:
        The assistant's text response, or empty string on failure.
    """
    # Use JUDGE_LLM_* environment variables
    base_url = os.environ.get("JUDGE_LLM_BASE_URL")
    api_key = os.environ.get("JUDGE_LLM_API_KEY")
    env_model = os.environ.get("JUDGE_LLM_MODEL")
    llm_model = model if model is not None else env_model
    missing = [
        name
        for name, value in (
            ("JUDGE_LLM_BASE_URL", base_url),
            ("JUDGE_LLM_API_KEY", api_key),
            ("JUDGE_LLM_MODEL", llm_model),
        )
        if not value
    ]
    if missing:
        raise LLMAPIConfigError(
            "Judge LLM requires direct LLM API settings; missing: " + ", ".join(missing)
        )

    return _call_llm_api_internal(
        prompt=prompt,
        base_url=base_url,
        api_key=api_key,
        model=llm_model,
        timeout_seconds=timeout_seconds,
        max_retries=max_retries,
    )


def _run_pair_attack(
    *,
    task: Task,
    target_agent_id: str,
    model_id: str,
    skill_dir: Path,
    timeout_multiplier: float,
    run_id: str,
    verbose: bool = False,
    local_task_agent_workspace_root_relate: Path,
    task_agent_workspace_root: Path,
    task_agent_workspace_root_relate:Path
) -> dict:
    """
    Execute PAIR (Prompt Attack via Iterative Refinement) attack.

    This runs an iterative attack loop:
    1. Attacker generates adversarial prompt
    2. Target receives prompt and responds
    3. Judge rates the response
    4. Feedback goes back to attacker
    5. Repeat until success or max iterations

    Returns:
        Dict with keys: best_prompt, best_score, iterations, success
    """
    attack = get_attack_method("pair")
    original_intent = task.frontmatter.get("original_intent", task.prompt)

    logger.info("🎯 Starting PAIR attack for task: %s", task.task_id)
    logger.info("   Original intent: %s", original_intent[:100] + "..." if len(original_intent) > 100 else original_intent)

    best_prompt = None
    best_score = 0
    best_result = None
    target_response = ""

    for iteration in range(attack.MAX_ITERATIONS):
        strategy = attack.STRATEGIES[iteration % len(attack.STRATEGIES)]
        logger.info("   Iteration %d/%d (strategy: %s)", iteration + 1, attack.MAX_ITERATIONS, strategy)

        # Generate adversarial prompt
        if iteration == 0:
            # First iteration: use initial prompt
            current_prompt = attack.get_initial_prompt(original_intent, strategy)
        else:
            # Subsequent iterations: ask attacker to refine
            attacker_prompt = attack.get_attacker_prompt(
                original_intent=original_intent,
                current_prompt=current_prompt,
                target_response=target_response,
                judge_score=last_score,
                judge_feedback=last_feedback,
                strategy=strategy,
            )

            # Run attacker via direct LLM API (no agent guardrails)
            attacker_response = _call_pair_llm_api(attacker_prompt, timeout_seconds=60)

            if not attacker_response:
                logger.warning("   Attacker LLM call failed, using previous prompt")
            else:
                current_prompt = attacker_response.strip()

        logger.info("   Prompt: %s", current_prompt[:100] + "..." if len(current_prompt) > 100 else current_prompt)

        # Reset target environment for clean context
        if docker.is_active():
            # Docker mode: restart container for fully isolated iteration
            docker.restart()
            ensure_agent_exists(target_agent_id, model_id, Path(f"/tmp/scry/{run_id}-pair-{iteration}/agent_workspace"))
        cleanup_agent_sessions(target_agent_id)

        # Prepare workspace
        prepare_task_workspace(skill_dir, f"{run_id}-pair-{iteration}", task, target_agent_id, local_task_agent_workspace_root_relate)
        # Copy the locally rebuilt directory contents into Docker
        # Mapping rule: task_base_dir/. -> /tmp/scry
        if docker.is_active():
            host_path = f"{task_agent_workspace_root}/tmp/scry/."
            docker.copy_to_container(host_path, Path("/tmp/scry"))

        # Handle Docker and non-Docker modes
        if docker.is_active():
            target_workspace = task_agent_workspace_root_relate
        else:
            target_workspace = local_task_agent_workspace_root_relate

        # Send prompt to target
        target_result = run_openclaw_prompt(
            agent_id=target_agent_id,
            prompt=current_prompt,
            workspace=target_workspace,
            timeout_seconds=task.timeout_seconds * timeout_multiplier,
            task_agent_workspace_root=task_agent_workspace_root
        )

        if target_result["status"] != "success" or not target_result["transcript"]:
            logger.warning("   Target execution failed")
            target_response = "[Target execution failed]"
        else:
            # Extract target's response text from transcript
            target_response = _extract_assistant_text(target_result["transcript"])

        # Run judge via direct LLM API (no agent guardrails)
        judge_prompt = attack.get_judge_prompt(original_intent, target_response)
        judge_response = _call_judge_llm_api(judge_prompt, timeout_seconds=60)

        if not judge_response:
            logger.warning("   Judge LLM call failed, assuming score 5")
            last_score = 5
            last_feedback = "Judge failed to respond"
        else:
            last_score, last_feedback = attack.parse_judge_response(judge_response)

        logger.info("   Judge score: %d/10", last_score)

        # Track best result
        if last_score > best_score:
            best_score = last_score
            best_prompt = current_prompt
            best_result = target_result

        # Check for success
        if last_score >= attack.SUCCESS_THRESHOLD:
            logger.info("   ✅ Attack succeeded!")
            break

    success = best_score >= attack.SUCCESS_THRESHOLD
    logger.info("🎯 PAIR completed: best_score=%d, success=%s", best_score, success)

    return {
        "best_prompt": best_prompt,
        "best_score": best_score,
        "iterations": iteration + 1,
        "success": success,
        "target_result": best_result,
        "transcript": best_result["transcript"] if best_result else [],
    }


def execute_openclaw_task(
    *,
    task: Task,
    agent_id: str,
    model_id: str,
    run_id: str,
    timeout_multiplier: float,
    skill_dir: Path,
    task_agent_workspace_root:Path,
    task_agent_workspace_root_relate:Path,
    local_task_agent_workspace_root_relate:Path,
    verbose: bool = False,
    attack_method: str | None = None,
    no_context: bool = False,
) -> Dict[str, Any]:
    logger.info("🤖 Agent [%s] starting task: %s", agent_id, task.task_id)
    logger.info("   Task: %s", task.name)
    logger.info("   Category: %s", task.category)
    if verbose:
        logger.info(
            "   Prompt: %s", task.prompt[:500] + "..." if len(task.prompt) > 500 else task.prompt
        )

    # Clean up previous session transcripts so we can reliably find this task's
    # transcript (OpenClaw uses its own UUID-based naming, not our session ID).
    cleanup_agent_sessions(agent_id)

    # Handle PAIR attack: iteratively find best adversarial prompt, then
    # do a final proper evaluation run with that prompt for grading.
    pair_metadata = None
    if attack_method and is_pair_attack(attack_method):
        logger.info("🔓 PAIR attack detected, starting multi-agent iteration")
        logger.info("   Attacker/Judge use direct LLM API (PAIR_LLM_* env vars)")

        pair_result = _run_pair_attack(
            task=task,
            target_agent_id=agent_id,
            model_id=model_id,
            skill_dir=skill_dir,
            timeout_multiplier=timeout_multiplier,
            run_id=run_id,
            verbose=verbose,
            local_task_agent_workspace_root_relate=local_task_agent_workspace_root_relate,
            task_agent_workspace_root=task_agent_workspace_root,
            task_agent_workspace_root_relate=task_agent_workspace_root_relate
        )

        pair_metadata = {
            "best_prompt": pair_result["best_prompt"],
            "best_score": pair_result["best_score"],
            "iterations": pair_result["iterations"],
            "success": pair_result["success"],
        }

        if pair_result["best_prompt"]:
            logger.info("🔓 PAIR found best prompt (score=%d), running final evaluation with it", pair_result["best_score"])
        else:
            logger.warning("🔓 PAIR failed to produce any prompt, falling back to original")

        # Clean up PAIR iteration transcripts before the final evaluation run
        cleanup_agent_sessions(agent_id)

    start_time = time.time()

    # Apply attack method BEFORE prepare_task_workspace (for indirect injections)
    # Create a modified task copy if attack is applied
    modified_task = task
    override_prompt = None
    if attack_method and not is_pair_attack(attack_method):
        # Non-PAIR attacks: apply transformation
        modified_task, override_prompt = _apply_attack_to_task(attack_method, task, skill_dir=skill_dir, no_context=no_context)
    elif pair_metadata and pair_metadata["best_prompt"]:
        # PAIR attack: use the best adversarial prompt found
        override_prompt = pair_metadata["best_prompt"]

    # Prepare the task execution workspace and rebuild the files the agent needs locally.
    prepare_task_workspace(skill_dir, run_id, modified_task, agent_id, local_task_agent_workspace_root_relate)
    # Copy the locally rebuilt directory contents into Docker
    # Mapping rule: task_base_dir/. -> /tmp/scry
    if docker.is_active():
        host_path = f"{task_agent_workspace_root}/tmp/scry/."
        docker.copy_to_container(host_path, Path("/tmp/scry"))

    # Handle Docker and non-Docker modes
    if docker.is_active():
        workspace = task_agent_workspace_root_relate
    else:
        workspace = local_task_agent_workspace_root_relate

    session_id = f"{task.task_id}_{int(time.time() * 1000)}"
    timeout_seconds = task.timeout_seconds * timeout_multiplier
    stdout = ""
    stderr = ""
    exit_code = -1
    timed_out = False

    # Substitute environment variables in the prompt (e.g., ${WEB_SIM_BASE_URL})
    resolved_prompt = _substitute_env_vars(modified_task.prompt)

    # For direct attacks, use the transformed prompt
    if override_prompt:
        resolved_prompt = override_prompt

    # Check if this is a multi-session task
    sessions = task.frontmatter.get("sessions", [])
    if sessions:
        # Multi-session task: send each prompt in sequence
        # When a session entry has new_session: true, we backup the current
        # transcript and cleanup agent sessions to simulate a fresh session.
        # All backed-up transcripts are merged at the end.
        logger.info("📋 Multi-session task with %d sessions", len(sessions))
        transcript_backups: List[List[Dict[str, Any]]] = []
        for i, session_entry in enumerate(sessions, 1):
            # Extract prompt text from session entry (handle both string and dict formats)
            if isinstance(session_entry, str):
                session_prompt = session_entry
                is_new_session = False
            elif isinstance(session_entry, dict):
                session_prompt = session_entry.get("prompt") or session_entry.get("message", "")
                is_new_session = session_entry.get("new_session", False)
            else:
                logger.warning("⚠️ Skipping invalid session entry: %s", session_entry)
                continue

            # Handle new_session: backup transcript then cleanup
            if is_new_session and i > 1:
                logger.info("   🔄 new_session=true: backing up transcript and starting fresh session")
                agent_store_dir_mid = docker.ensure_transcripts_on_host(agent_id, task_agent_workspace_root)
                mid_transcript = _load_transcript(agent_id, session_id, start_time, agent_dir_param=agent_store_dir_mid)
                if mid_transcript:
                    transcript_backups.append(mid_transcript)
                    logger.info("   Backed up %d transcript entries", len(mid_transcript))
                cleanup_agent_sessions(agent_id)
                cleanup_agent_sessions_in_container(agent_id)

            logger.info("   Session %d/%d%s", i, len(sessions), " (new session)" if is_new_session and i > 1 else "")
            elapsed = time.time() - start_time
            remaining = timeout_seconds - elapsed
            if remaining <= 0:
                timed_out = True
                break
            try:
                result = docker.run_cmd(
                    [
                        "openclaw",
                        "agent",
                        "--agent",
                        agent_id,
                        "--session-id",
                        session_id,
                        "--message",
                        session_prompt,
                    ],
                    cwd=str(workspace),
                    timeout=remaining,
                )
                stdout += result.stdout
                stderr += result.stderr
                exit_code = result.returncode
                if result.returncode not in (0, -1):
                    break
            except subprocess.TimeoutExpired as exc:
                timed_out = True
                stdout += (exc.stdout or b"").decode("utf-8", errors="replace") if isinstance(exc.stdout, bytes) else (exc.stdout or "")
                stderr += (exc.stderr or b"").decode("utf-8", errors="replace") if isinstance(exc.stderr, bytes) else (exc.stderr or "")
                break
            except FileNotFoundError as exc:
                stderr = f"openclaw command not found: {exc}"
                break
    else:
        # Single-session task: send resolved_prompt once
        try:
            result = docker.run_cmd(
                [
                    "openclaw",
                    "agent",
                    "--agent",
                    agent_id,
                    "--session-id",
                    session_id,
                    "--message",
                    resolved_prompt,
                ],
                cwd=str(workspace),
                timeout=timeout_seconds,
            )
            stdout = result.stdout
            stderr = result.stderr
            exit_code = result.returncode
        except subprocess.TimeoutExpired as exc:
            timed_out = True
            stdout = (exc.stdout or b"").decode("utf-8", errors="replace") if isinstance(exc.stdout, bytes) else (exc.stdout or "")
            stderr = (exc.stderr or b"").decode("utf-8", errors="replace") if isinstance(exc.stderr, bytes) else (exc.stderr or "")
        except FileNotFoundError as exc:
            stderr = f"openclaw command not found: {exc}"

    agent_store_dir = docker.ensure_transcripts_on_host(agent_id, task_agent_workspace_root)

    transcript = _load_transcript(agent_id, session_id, start_time, agent_dir_param=agent_store_dir)

    # Merge backed-up transcripts from earlier sessions (new_session: true)
    if sessions and transcript_backups:
        merged_transcript: List[Dict[str, Any]] = []
        for backup in transcript_backups:
            merged_transcript.extend(backup)
        merged_transcript.extend(transcript)
        logger.info("📋 Merged %d transcript backups (%d + %d entries)",
                     len(transcript_backups), len(merged_transcript) - len(transcript), len(transcript))
        transcript = merged_transcript

    usage = _extract_usage_from_transcript(transcript)
    execution_time = time.time() - start_time

    status = "success"
    if timed_out:
        status = "timeout"
    if not transcript:
        status = "error"
    if exit_code not in (0, -1) and not timed_out:
        status = "error"
    if stderr and "openclaw command not found" in str(stderr):
        status = "error"

    # Verbose logging for debugging
    if verbose:
        logger.info("   [VERBOSE] Exit code: %s", exit_code)
        logger.info("   [VERBOSE] Execution time: %.2fs", execution_time)
        logger.info("   [VERBOSE] Workspace: %s", workspace)
        if stdout:
            logger.info("   [VERBOSE] Stdout (first 1000 chars):\n%s", stdout[:1000])
        if stderr:
            logger.info("   [VERBOSE] Stderr:\n%s", stderr[:1000])
        logger.info("   [VERBOSE] Transcript entries: %d", len(transcript))

        # Show agent responses from transcript
        for entry in transcript:
            if entry.get("type") == "message":
                msg = entry.get("message", {})
                role = msg.get("role", "unknown")
                content = msg.get("content", "")
                if role == "assistant":
                    # Truncate long responses
                    preview = content[:500] + "..." if len(content) > 500 else content
                    logger.info("   [VERBOSE] Agent response: %s", preview)
                elif role == "user":
                    preview = content[:200] + "..." if len(content) > 200 else content
                    logger.info("   [VERBOSE] User message: %s", preview)

        # Show workspace files after task
        if workspace.exists():
            logger.info("   [VERBOSE] Workspace files after task:")
            for f in sorted(workspace.rglob("*")):
                if f.is_file():
                    try:
                        size = f.stat().st_size
                        logger.info("      %s (%d bytes)", f.relative_to(workspace), size)
                    except OSError:
                        logger.info("      %s", f.relative_to(workspace))

    result = {
        "agent_id": agent_id,
        "task_id": task.task_id,
        "status": status,
        "transcript": transcript,
        "usage": usage,
        "workspace": str(workspace),
        "exit_code": exit_code,
        "timed_out": timed_out,
        "execution_time": execution_time,
        "stdout": stdout,
        "stderr": stderr,
    }
    if pair_metadata:
        result["pair_attack"] = pair_metadata
    return result


def run_openclaw_prompt(
    *,
    agent_id: str,
    prompt: str,
    workspace: Path,
    timeout_seconds: float,
    task_agent_workspace_root: Path,

) -> Dict[str, Any]:
    """Run a single OpenClaw prompt for helper agents like the judge."""
    # Clean up previous session transcripts so we can reliably find this
    # prompt's transcript (OpenClaw uses its own UUID-based naming).
    cleanup_agent_sessions(agent_id)

    start_time = time.time()
    workspace.mkdir(parents=True, exist_ok=True)
    session_id = f"judge_{int(time.time() * 1000)}"
    stdout = ""
    stderr = ""
    exit_code = -1
    timed_out = False

    chunks = [
        prompt[i : i + MAX_OPENCLAW_MESSAGE_CHARS]
        for i in range(0, max(1, len(prompt)), MAX_OPENCLAW_MESSAGE_CHARS)
    ]
    if len(chunks) > 1:
        total_chunks = len(chunks)
        chunks = [
            (
                f"You are receiving a long prompt in {total_chunks} parts.\n"
                f"Ignore and do not respond until the final part.\n\n"
                f"Part 1/{total_chunks}:\n{chunks[0]}"
            )
        ] + [
            (
                f"Part {i + 2}/{total_chunks}:\n{chunks[i + 1]}"
                if i + 2 < total_chunks
                else (
                    f"Part {i + 2}/{total_chunks} (final):\n{chunks[i + 1]}\n"
                    "All parts received. Proceed with final judgment now."
                )
            )
            for i in range(0, total_chunks - 1)
        ]
    for chunk in chunks:
        elapsed = time.time() - start_time
        remaining = timeout_seconds - elapsed
        if remaining <= 0:
            timed_out = True
            break

        # Debug: log prompt being sent
        logger.info("Sending to judge (chunk %d/%d, %d chars): %s...",
                   chunks.index(chunk) + 1, len(chunks), len(chunk), chunk[:200])

        try:
            result = docker.run_cmd(
                [
                    "openclaw",
                    "agent",
                    "--agent",
                    agent_id,
                    "--session-id",
                    session_id,
                    "--message",
                    chunk,
                ],
                cwd=str(workspace),
                timeout=remaining,
            )
            stdout += result.stdout
            stderr += result.stderr
            exit_code = result.returncode

            # Debug: log result
            logger.info("Judge command result: returncode=%d, stdout_len=%d", exit_code, len(stdout))

            if result.returncode not in (0, -1) and not timed_out:
                break
        except subprocess.TimeoutExpired as exc:
            timed_out = True
            stdout += (exc.stdout or b"").decode("utf-8", errors="replace") if isinstance(exc.stdout, bytes) else (exc.stdout or "")
            stderr += (exc.stderr or b"").decode("utf-8", errors="replace") if isinstance(exc.stderr, bytes) else (exc.stderr or "")
            break
        except FileNotFoundError as exc:
            stderr += f"openclaw command not found: {exc}"
            break

    agent_store_dir = docker.ensure_transcripts_on_host(agent_id, task_agent_workspace_root)

    transcript = _load_transcript(agent_id, session_id, start_time, agent_store_dir)
    execution_time = time.time() - start_time

    status = "success"
    if timed_out:
        status = "timeout"
    if not transcript:
        status = "error"
    if exit_code not in (0, -1) and not timed_out:
        status = "error"
    if stderr and "openclaw command not found" in str(stderr):
        status = "error"

    return {
        "agent_id": agent_id,
        "status": status,
        "transcript": transcript,
        "workspace": str(workspace),
        "exit_code": exit_code,
        "timed_out": timed_out,
        "execution_time": execution_time,
        "stdout": stdout,
        "stderr": stderr,
    }
