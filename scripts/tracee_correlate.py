#!/usr/bin/env python3
"""
Tracee Log and OpenClaw Tool Call Correlation Analysis

This module correlates OpenClaw tool calls with Tracee system events,
generating structured reports for security analysis.

Main components:
- Log parsing: Extract tool calls and tracee events
- Process tree: Build process hierarchy from execve events
- Command matching: Match exec commands with processes using argv patterns
- Correlation: Associate tool calls with system events
- Report generation: Output structured JSON reports

Public API:
- correlate_task_logs(): Main entry point for benchmark.py
"""

from __future__ import annotations

import json
import logging
import re
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)


# =============================================================================
# CONSTANTS
# =============================================================================

# System path prefixes - these are automatically loaded dependencies, not business files
SYSTEM_PATH_PREFIXES = (
    "/usr/lib",
    "/usr/lib64",
    "/lib",
    "/lib64",
    "/usr/local/lib",
    "/usr/local/bin",
    "/usr/share",
    "/usr/bin",
    "/bin",
    "/usr/sbin",
    "/sbin",
    "/proc",
    "/sys",
    "/dev",
    "/etc/ld.so",
    "/etc/ssl",
    "/etc/openssl",
    "/etc/hosts",
    "/etc/resolv.conf",
    "/etc/nsswitch.conf",
    "/etc/localtime",
    "/etc/timezone",
    "/etc/profile",
    "/etc/profile.d",
    "/etc/passwd",
    "/etc/group",
    "/etc/shells",
    "/etc/bash.bashrc",
    "/root/.profile",
    "/root/.bashrc",
    "/root/.bash_profile",
    "/root/.local/bin/env",
    "/var/lib/dpkg",
    "/var/lib/apt",
    "/var/cache",
    "/run",
    "/tmp/.X",
    "/tmp/_MEI",
)

# System file patterns - auto-loaded library files
SYSTEM_FILE_PATTERNS = (
    ".so",
    ".so.",
    "ld-linux",
    "libc.so",
    "libpthread",
    "libdl",
    "libm.so",
    "librt.so",
    "libresolv",
    "libnss_",
    "libnsl",
)

# Shell builtin commands - these don't spawn independent processes
SHELL_BUILTINS = frozenset({
    "cd", "echo", "export", "source", ".", "alias", "unalias",
    "set", "unset", "read", "printf", "test", "[", "[[",
    "true", "false", "exit", "return", "break", "continue",
    "shift", "eval", "exec", "trap", "wait", "jobs", "bg", "fg",
    "local", "declare", "typeset", "readonly", "let",
    "for", "do", "done", "while", "until", "if", "then", "else",
    "elif", "fi", "case", "esac", "in", "select", "time", "coproc",
})

# Linux kernel process name length limit (including null terminator)
TASK_COMM_LEN = 16

# Event types that need to be processed (for early filtering)
FILTER_EVENT_TYPES = frozenset({
    "execve",                      # Process execution
    "security_file_open",          # File access
    "security_socket_connect",     # Network connection
    "security_socket_create",      # Socket creation
    "net_packet_dns",              # DNS query
})


# =============================================================================
# DATA CLASSES
# =============================================================================

@dataclass(slots=True)
class ToolCall:
    """OpenClaw tool call record."""
    timestamp: str
    tool: str
    params: dict[str, Any]
    result: str | None = None
    tracee_events: list[dict] = field(default_factory=list)
    assigned_pids: set[int] = field(default_factory=set)
    expected_patterns: list[str] = field(default_factory=list)


@dataclass(slots=True)
class ProcessInfo:
    """Process information for building process tree."""
    pid: int
    ppid: int
    process_name: str
    argv: list[str]
    timestamp: int
    executable_path: str = ""


@dataclass(slots=True)
class CommandPattern:
    """Command matching pattern for precise process matching."""
    process_name: str
    argv_prefix: list[str] | None = None
    is_heredoc_or_inline: bool = False
    executable_path: str | None = None


# =============================================================================
# PATH UTILITIES
# =============================================================================

def is_system_path(pathname: str | None) -> bool:
    """Check if a file path is a system auto-loaded file (should be filtered out).

    Args:
        pathname: File path to check.

    Returns:
        True if it's a system path, False if it's a business-relevant path.
    """
    if not pathname:
        return True  # Empty path treated as system path

    # Check system path prefixes
    for prefix in SYSTEM_PATH_PREFIXES:
        if pathname.startswith(prefix):
            return True

    # Check file name patterns
    filename = pathname.split("/")[-1] if "/" in pathname else pathname
    for pattern in SYSTEM_FILE_PATTERNS:
        if pattern in filename:
            return True

    return False


def normalize_path(path: str) -> str:
    """Normalize file path for correlation matching.

    Expands ~ and $HOME environment variables.
    In Docker containers, ~ and $HOME typically point to /root.

    Args:
        path: Original path.

    Returns:
        Normalized absolute path.
    """
    if not path:
        return path

    # Expand ~ to /root (root user in Docker container)
    if path.startswith("~/"):
        path = "/root/" + path[2:]
    elif path == "~":
        path = "/root"

    # Expand $HOME environment variable
    path = path.replace("$HOME", "/root")
    path = path.replace("${HOME}", "/root")

    return path


def paths_match(path1: str, path2: str) -> bool:
    """Check if two paths match (with normalization).

    Args:
        path1: First path.
        path2: Second path.

    Returns:
        True if paths match.
    """
    norm_path1 = normalize_path(path1).rstrip("/")
    norm_path2 = normalize_path(path2).rstrip("/")
    return norm_path1 == norm_path2


def process_name_matches(expected: str, actual: str) -> bool:
    """Check if process names match (considering kernel truncation).

    Linux kernel limits process names to TASK_COMM_LEN - 1 = 15 characters.

    Args:
        expected: Expected process name (may be full path or command name).
        actual: Actual process name captured by Tracee (may be truncated).

    Returns:
        True if names match.
    """
    if expected == actual:
        return True

    # Check if expected name is truncated
    if len(expected) >= TASK_COMM_LEN:
        truncated = expected[:TASK_COMM_LEN - 1]
        if truncated == actual:
            return True

    # Check if actual name is a prefix of expected (truncation case)
    if len(actual) == TASK_COMM_LEN - 1 and expected.startswith(actual):
        return True

    return False


def executable_path_matches(expected_path: str, actual_path: str) -> bool:
    """Check if executable paths match.

    Args:
        expected_path: Expected path (may contain ~).
        actual_path: Actual path captured by Tracee.

    Returns:
        True if paths match.
    """
    if not expected_path or not actual_path:
        return False

    norm_expected = normalize_path(expected_path)
    norm_actual = actual_path

    if norm_expected == norm_actual:
        return True

    # Handle relative vs absolute paths
    if norm_expected.endswith(norm_actual) or norm_actual.endswith(norm_expected):
        return True

    return False


# =============================================================================
# LOG PARSING
# =============================================================================

def parse_openclaw_log(log_path: Path) -> list[ToolCall]:
    """Parse OpenClaw log and extract tool calls.

    Supports formats:
    - With timestamp: 2026-04-16 19:14:38,123 - INFO - Tool: tool_name({...})
    - Without timestamp: Tool: tool_name({...})
    """
    tool_calls = []
    current_call = None

    # Regex patterns for tool call lines
    tool_pattern_with_ts = re.compile(
        r'^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}).*Tool: (\w+)\((.*)\)$'
    )
    tool_pattern_no_ts = re.compile(r'^Tool: (\w+)\((.*)\)$')

    with open(log_path, encoding='utf-8') as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()

            # Try timestamp format first
            tool_match = tool_pattern_with_ts.match(line)
            if tool_match:
                if current_call:
                    tool_calls.append(current_call)
                timestamp, tool, params_str = tool_match.groups()
                params = _parse_params(params_str, line_num)
                current_call = ToolCall(timestamp=timestamp, tool=tool, params=params)
                continue

            # Try non-timestamp format
            tool_match = tool_pattern_no_ts.match(line)
            if tool_match:
                if current_call:
                    tool_calls.append(current_call)
                tool, params_str = tool_match.groups()
                params = _parse_params(params_str, line_num)
                current_call = ToolCall(timestamp="", tool=tool, params=params)
                continue

            # Match result line
            if current_call and line.startswith('Result:'):
                current_call.result = line[7:].strip()

    if current_call:
        tool_calls.append(current_call)

    return tool_calls


def _parse_params(params_str: str, line_num: int) -> dict:
    """Parse JSON parameters from tool call string."""
    params_str = params_str.strip()
    if params_str.endswith(','):
        params_str = params_str[:-1]
    try:
        return json.loads(params_str) if params_str else {}
    except json.JSONDecodeError as e:
        logger.warning("Failed to parse params at line %d: %s", line_num, e)
        return {"raw": params_str}


def parse_tracee_log(
    log_path: Path,
    filter_events: bool = True,
    filter_system_paths: bool = True,
) -> list[dict]:
    """Parse Tracee log file with early filtering for performance.

    Early filtering reduces memory usage and improves performance by:
    1. Skip events not in FILTER_EVENT_TYPES
    2. Skip system path file access events

    Args:
        log_path: Path to tracee log file.
        filter_events: Whether to filter by event type (default True).
        filter_system_paths: Whether to filter system path events (default True).

    Returns:
        List of tracee events (filtered or all).
    """
    with open(log_path, encoding='utf-8') as f:
        content = f.read().strip()

    # Try parsing as JSON array
    if content.startswith('['):
        try:
            events = json.loads(content)
            if filter_events:
                return [e for e in events if _should_keep_event(e, filter_system_paths)]
            return events
        except json.JSONDecodeError:
            pass

    # Parse line by line as JSON Lines
    events = []
    for line in content.split('\n'):
        line = line.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
            if filter_events and not _should_keep_event(event, filter_system_paths):
                continue
            events.append(event)
        except json.JSONDecodeError:
            continue

    return events


def _should_keep_event(event: dict, filter_system_paths: bool) -> bool:
    """Check if event should be kept based on filtering rules.

    Early filtering rules:
    1. Keep only events in FILTER_EVENT_TYPES (execve, security_file_open, etc.)
    2. For security_file_open, filter out system paths if enabled
    """
    event_name = event.get("eventName")

    # Only keep events we care about
    if event_name not in FILTER_EVENT_TYPES:
        return False

    # Filter system paths for file access events
    if filter_system_paths and event_name == "security_file_open":
        pathname = extract_pathname(event)
        if is_system_path(pathname):
            return False

    return True


def extract_tool_calls_from_transcript(transcript_path: Path, output_path: Path | None = None) -> list[ToolCall]:
    """Extract tool calls from OpenClaw transcript file.

    Args:
        transcript_path: Path to transcript file (JSONL format).
        output_path: Optional path to write OpenClaw log file.

    Returns:
        List of tool calls.
    """
    tool_calls = []

    with open(transcript_path, encoding='utf-8') as f:
        lines = f.readlines()

    for line in lines:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue

        entry_type = entry.get("type")

        # Format 1: Standalone toolCall entry
        if entry_type == "toolCall":
            tool_calls.append(ToolCall(
                timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S,%f")[:-3],
                tool=entry.get("name", ""),
                params=entry.get("arguments", {}),
            ))
            continue

        # Format 2: toolResult entry
        if entry_type == "toolResult":
            content = entry.get("content", [])
            result_text = _extract_result_text(content)
            _set_tool_call_result(tool_calls, result_text)
            continue

        # Format 3: message with toolCall
        if entry_type == "message":
            msg = entry.get("message", {})
            if msg.get("role") == "assistant":
                for block in msg.get("content", []):
                    if isinstance(block, dict) and block.get("type") == "toolCall":
                        tool_calls.append(ToolCall(
                            timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S,%f")[:-3],
                            tool=block.get("name", ""),
                            params=block.get("arguments", {}),
                        ))
            elif msg.get("role") == "user":
                for block in msg.get("content", []):
                    if isinstance(block, dict) and block.get("type") == "tool_result":
                        _set_tool_call_result(tool_calls, str(block.get("content", ""))[:500])

    # Write log file if output path specified
    if output_path:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, "w", encoding='utf-8') as f:
            for call in tool_calls:
                params_str = json.dumps(call.params, ensure_ascii=False)
                f.write(f"Tool: {call.tool}({params_str})\n")
                if call.result:
                    f.write(f"Result: {call.result[:500]}\n")
        logger.info("Generated OpenClaw tool call log: %s", output_path)

    return tool_calls


def _extract_result_text(content: Any) -> str:
    """Extract text from tool result content."""
    if isinstance(content, list):
        result_text = ""
        for block in content:
            if isinstance(block, dict) and block.get("type") == "text":
                result_text += block.get("text", "")
            elif isinstance(block, str):
                result_text += block
        return result_text
    return str(content)


def _set_tool_call_result(tool_calls: list[ToolCall], result: str) -> None:
    """Set result for the most recent tool call without a result."""
    for call in reversed(tool_calls):
        if call.result is None:
            call.result = result[:500] if len(result) > 500 else result
            break


def extract_pathname(event: dict) -> str | None:
    """Extract file pathname from tracee event."""
    for arg in event.get("args", []):
        if arg.get("name") == "pathname":
            return arg.get("value")
    return None


# =============================================================================
# PROCESS TREE
# =============================================================================

def parse_execve_events(tracee_events: list[dict]) -> dict[int, ProcessInfo]:
    """Parse execve events from tracee log and build process info mapping.

    Args:
        tracee_events: List of tracee events.

    Returns:
        Mapping from process ID to ProcessInfo.
    """
    process_map: dict[int, ProcessInfo] = {}

    for event in tracee_events:
        if event.get("eventName") != "execve":
            continue

        pid = event.get("processId")
        if pid is None:
            continue

        ppid = event.get("parentProcessId", 0)
        process_name = event.get("processName", "")
        timestamp = event.get("timestamp", 0)

        # Extract argv and pathname from args
        argv = []
        executable_path = ""
        for arg in event.get("args", []):
            if arg.get("name") == "argv":
                val = arg.get("value", [])
                argv = val if isinstance(val, list) else [val]
            elif arg.get("name") == "pathname":
                executable_path = arg.get("value", "")

        # Extract actual process name from executable_path if available
        # (event.processName may be parent process name like "sh")
        if executable_path:
            actual_process_name = executable_path.split("/")[-1] if "/" in executable_path else executable_path
        else:
            actual_process_name = process_name

        # Keep the last execve if same PID has multiple (overwrite)
        process_map[pid] = ProcessInfo(
            pid=pid,
            ppid=ppid or 0,
            process_name=actual_process_name,
            argv=argv,
            timestamp=timestamp,
            executable_path=executable_path,
        )

    return process_map


def build_process_tree(process_map: dict[int, ProcessInfo]) -> dict[int, dict]:
    """Build process tree structure.

    Args:
        process_map: Mapping from process ID to ProcessInfo.

    Returns:
        Process tree with parent-child relationships.
    """
    tree: dict[int, dict] = {}

    for pid, info in process_map.items():
        tree[pid] = {
            "info": info,
            "parent_pid": info.ppid,
            "children": [],
        }

    # Establish parent-child relationships
    for pid, node in tree.items():
        ppid = node["parent_pid"]
        if ppid in tree:
            tree[ppid]["children"].append(pid)

    return tree


def get_all_descendants(process_tree: dict, pid: int, visited: set[int] | None = None) -> set[int]:
    """Recursively get all descendant processes (including self).

    Args:
        process_tree: Process tree structure.
        pid: Starting process ID.
        visited: Set of visited PIDs (to prevent cycles).

    Returns:
        Set of all descendant PIDs (including the starting PID).
    """
    if visited is None:
        visited = set()

    if pid in visited:
        return set()

    visited.add(pid)
    descendants = {pid}

    if pid in process_tree:
        for child_pid in process_tree[pid].get("children", []):
            descendants.update(get_all_descendants(process_tree, child_pid, visited))

    return descendants


# =============================================================================
# COMMAND MATCHING
# =============================================================================

def get_truncated_process_name(name: str) -> str:
    """Get kernel-truncated process name (max 15 chars)."""
    if len(name) >= TASK_COMM_LEN:
        return name[:TASK_COMM_LEN - 1]
    return name


def extract_process_pattern_from_command(command: str) -> list[CommandPattern]:
    """Extract command matching patterns from exec command string.

    For complex commands (with &&, ||, |, ;), extracts all sub-command patterns.

    Args:
        command: Exec command string like "ls -la", "python3 script.py", "bash -c 'echo hello'".

    Returns:
        List of command patterns with process name and optional argv prefix.
    """
    if not command:
        return []

    command = command.strip().replace("\\\n", " ")

    # Split command to get all sub-commands
    sub_commands = [command]
    for sep in [";", "&&", "||", "|"]:
        new_sub_commands = []
        for cmd in sub_commands:
            new_sub_commands.extend(cmd.split(sep))
        sub_commands = new_sub_commands

    patterns: list[CommandPattern] = []

    for sub_cmd in sub_commands:
        sub_cmd = sub_cmd.strip()
        pattern = _parse_single_command(sub_cmd)
        if pattern:
            patterns.extend(pattern)

    return patterns


def _parse_single_command(sub_cmd: str) -> list[CommandPattern]:
    """Parse a single command and extract patterns."""
    # Handle heredoc: `python3 << 'EOF'`
    heredoc_pattern = _extract_heredoc_pattern(sub_cmd)
    if heredoc_pattern:
        return heredoc_pattern

    # Handle redirection
    for redir in [" > ", " >> ", " 2>", " 2>&1", " 2>/dev/null", " 2> "]:
        if redir in sub_cmd:
            sub_cmd = sub_cmd.split(redir)[0].strip()
            break

    # Parse command parts (handle quoted arguments)
    parts = _split_command_with_quotes(sub_cmd)
    if not parts:
        return []

    first_word = parts[0]

    # Handle shell commands with -c
    if first_word in ("sh", "bash", "zsh", "fish", "dash", "ksh"):
        for i, part in enumerate(parts):
            if part == "-c" and i + 1 < len(parts):
                inner_command = parts[i + 1].strip("'\"")
                inner_patterns = extract_process_pattern_from_command(inner_command)
                for p in inner_patterns:
                    p.is_heredoc_or_inline = True
                return inner_patterns
        # No -c found, return shell pattern
        return [CommandPattern(process_name=first_word)]

    # Skip shell builtins
    if first_word in SHELL_BUILTINS:
        return []

    # Handle -c mode: `python3 -c "..."`
    if len(parts) >= 2 and parts[1] == "-c":
        return [CommandPattern(
            process_name=first_word,
            argv_prefix=[first_word, "-c"],
            is_heredoc_or_inline=True,
            executable_path=normalize_path(first_word) if "/" in first_word else None,
        )]

    # Regular command with arguments
    return _build_command_pattern(parts)


def _extract_heredoc_pattern(sub_cmd: str) -> list[CommandPattern] | None:
    """Extract pattern from heredoc command."""
    heredoc_markers = ["<< 'EOF'", '<< "EOF"', "<<EOF", "<< 'eof'", '<< "eof"', "<<eof"]
    for marker in heredoc_markers:
        if marker.lower() in sub_cmd.lower():
            before_heredoc = sub_cmd.split(marker)[0].strip()
            parts = before_heredoc.split()
            if parts and parts[0] not in SHELL_BUILTINS:
                return [CommandPattern(
                    process_name=parts[0],
                    argv_prefix=[parts[0]],
                    is_heredoc_or_inline=True,
                    executable_path=normalize_path(parts[0]) if "/" in parts[0] else None,
                )]
    return None


def _split_command_with_quotes(sub_cmd: str) -> list[str]:
    """Split command while respecting quotes."""
    raw_parts = sub_cmd.split()
    parts = []
    i = 0

    while i < len(raw_parts):
        part = raw_parts[i]
        # Check for opening quote without closing
        if (part.startswith("'") and not part.endswith("'")) or \
           (part.startswith('"') and not part.endswith('"')):
            quote_char = part[0]
            merged = part
            j = i + 1
            while j < len(raw_parts):
                merged += ' ' + raw_parts[j]
                if raw_parts[j].endswith(quote_char):
                    break
                j += 1
            parts.append(merged.strip(quote_char))
            i = j + 1
        else:
            parts.append(part.strip("'\""))
            i += 1

    return parts


def _build_command_pattern(parts: list[str]) -> list[CommandPattern]:
    """Build command pattern from parsed parts."""
    first_word = parts[0]

    # Build argv_prefix (keep full path if present)
    argv_prefix = [normalize_path(first_word) if "/" in first_word else first_word]
    executable_path = normalize_path(first_word) if "/" in first_word else None

    # Add meaningful arguments (skip options, keep paths/filenames)
    for part in parts[1:4]:  # Max 3 additional args
        if part in (">", ">>", "2>", "&>", "&>>"):
            break
        if part.startswith("-") and not part.startswith(("./", "/")):
            continue
        normalized_part = normalize_path(part)
        argv_prefix.append(normalized_part)
        if "/" in normalized_part or normalized_part.endswith((".py", ".sh")):
            break

    process_name = first_word.split("/")[-1] if "/" in first_word else first_word

    return [CommandPattern(
        process_name=process_name,
        argv_prefix=argv_prefix if len(argv_prefix) > 1 else None,
        executable_path=executable_path,
    )]


def match_score_argv(argv: list[str], command: str, executable_path: str | None = None) -> int:
    """Calculate match score between argv and command.

    Higher scores indicate better matches:
    - 0: No match
    - 1-99: Process name + partial args match
    - 100: Exact argv match
    - 101: Exact match + heredoc mode
    - 110: Executable path match
    - 120: Executable path + argv exact match

    Args:
        argv: Process command line arguments.
        command: Exec command string.
        executable_path: Full executable path from Tracee.

    Returns:
        Match score.
    """
    if not argv:
        return 0

    patterns = extract_process_pattern_from_command(command)
    if not patterns:
        return 0

    best_score = 0
    for pattern in patterns:
        score = _calculate_pattern_score(argv, pattern, executable_path)
        best_score = max(best_score, score)

    return best_score


def _calculate_pattern_score(argv: list[str], pattern: CommandPattern, executable_path: str | None) -> int:
    """Calculate score for a single pattern."""
    # Check executable_path match
    exec_path_matched = (
        executable_path and pattern.executable_path and
        executable_path_matches(pattern.executable_path, executable_path)
    )

    # Check process name match (with truncation)
    process_name_matched = argv and process_name_matches(pattern.process_name, argv[0])

    if not exec_path_matched and not process_name_matched:
        return 0

    # Calculate score based on argv match
    if not pattern.argv_prefix:
        # No argv_prefix, only process name match
        if exec_path_matched:
            return 110
        return 100 if len(argv) == 1 else 1

    # Check exact match
    if argv == pattern.argv_prefix:
        if exec_path_matched:
            return 120
        return 101 if pattern.is_heredoc_or_inline else 100

    # Check prefix match
    if len(argv) >= len(pattern.argv_prefix):
        match_len = 0
        for i, expected_arg in enumerate(pattern.argv_prefix):
            if i < len(argv) and argv[i] == expected_arg:
                match_len = i + 1
            else:
                break
        if match_len > 0:
            return 110 + match_len if exec_path_matched else match_len

    # argv only has process name, but pattern expects more
    if len(argv) == 1 and len(pattern.argv_prefix) > 1:
        return 110 if exec_path_matched else 1

    return 0


# =============================================================================
# EVENT HANDLERS (Dispatch Table Pattern)
# =============================================================================

def _handle_file_access_event(
    call: ToolCall,
    event: dict,
    context: dict,
) -> None:
    """Handle security_file_open event."""
    pathname = extract_pathname(event)
    if is_system_path(pathname):
        return

    call.tracee_events.append({
        "timestamp": event.get("timestamp"),
        "eventName": event.get("eventName"),
        "processName": context["process_name"],
        "processId": context["pid"],
        "parentProcessId": event.get("parentProcessId"),
        "pathname": pathname,
        "argv": context["argv_str"],
        "executablePath": context["executable_path"],
        "eventType": "file_access",
    })


def _handle_network_connect_event(
    call: ToolCall,
    event: dict,
    context: dict,
) -> None:
    """Handle security_socket_connect event."""
    remote_addr = None
    for arg in event.get("args", []):
        if arg.get("name") == "remote_addr":
            remote_addr = arg.get("value")
            break

    # Filter local connections
    if remote_addr and isinstance(remote_addr, dict):
        sa_family = remote_addr.get("sa_family", "")
        if sa_family == "AF_UNIX":
            return
        sin_addr = remote_addr.get("sin_addr", "")
        if sin_addr in ("127.0.0.1", "::1", "localhost"):
            return

    call.tracee_events.append({
        "timestamp": event.get("timestamp"),
        "eventName": event.get("eventName"),
        "processName": context["process_name"],
        "processId": context["pid"],
        "parentProcessId": event.get("parentProcessId"),
        "remote_addr": remote_addr,
        "argv": context["argv_str"],
        "executablePath": context["executable_path"],
        "eventType": "network_connect",
    })


def _handle_socket_create_event(
    call: ToolCall,
    event: dict,
    context: dict,
) -> None:
    """Handle security_socket_create event."""
    socket_type = None
    for arg in event.get("args", []):
        if arg.get("name") == "type":
            socket_type = arg.get("value")
            break

    call.tracee_events.append({
        "timestamp": event.get("timestamp"),
        "eventName": event.get("eventName"),
        "processName": context["process_name"],
        "processId": context["pid"],
        "parentProcessId": event.get("parentProcessId"),
        "socket_type": socket_type,
        "argv": context["argv_str"],
        "executablePath": context["executable_path"],
        "eventType": "socket_create",
    })


def _handle_dns_event(
    call: ToolCall,
    event: dict,
    context: dict,
) -> None:
    """Handle net_packet_dns event."""
    dns_query = None
    dns_answers = []
    src_ip = None
    dst_ip = None
    direction = None

    for arg in event.get("args", []):
        arg_name = arg.get("name", "")
        arg_value = arg.get("value")

        if arg_name == "proto_dns" and isinstance(arg_value, dict):
            questions = arg_value.get("questions", [])
            if questions:
                dns_query = questions[0].get("name", "")
            for ans in arg_value.get("answers", []):
                ip = ans.get("IP", "")
                if ip:
                    dns_answers.append(ip)
        elif arg_name == "src":
            src_ip = arg_value
        elif arg_name == "dst":
            dst_ip = arg_value
        elif arg_name == "metadata" and isinstance(arg_value, dict):
            direction = arg_value.get("direction")

    if dns_query:
        call.tracee_events.append({
            "timestamp": event.get("timestamp"),
            "eventName": event.get("eventName"),
            "processName": context["process_name"],
            "processId": context["pid"],
            "parentProcessId": event.get("parentProcessId"),
            "dns_query": dns_query,
            "dns_answers": dns_answers,
            "src_ip": src_ip,
            "dst_ip": dst_ip,
            "direction": "response" if direction == 1 else "query",
            "argv": context["argv_str"],
            "executablePath": context["executable_path"],
            "eventType": "dns_query",
        })


def _handle_execve_event(
    call: ToolCall,
    event: dict,
    context: dict,
) -> None:
    """Handle execve event - process execution."""
    # Extract argv from event
    argv = []
    for arg in event.get("args", []):
        if arg.get("name") == "argv":
            val = arg.get("value", [])
            argv = val if isinstance(val, list) else [val]
            break

    # Extract executable path
    executable_path = ""
    for arg in event.get("args", []):
        if arg.get("name") == "pathname":
            executable_path = arg.get("value", "")
            break

    call.tracee_events.append({
        "timestamp": event.get("timestamp"),
        "eventName": event.get("eventName"),
        "processName": context["process_name"],
        "processId": context["pid"],
        "parentProcessId": event.get("parentProcessId"),
        "argv": argv,
        "executablePath": executable_path or context["executable_path"],
        "eventType": "process_exec",
    })


# Event dispatch table: eventName -> handler function
EVENT_HANDLERS: dict[str, callable] = {
    "execve": _handle_execve_event,
    "security_file_open": _handle_file_access_event,
    "security_socket_connect": _handle_network_connect_event,
    "security_socket_create": _handle_socket_create_event,
    "net_packet_dns": _handle_dns_event,
}


# =============================================================================
# CORRELATION
# =============================================================================

def correlate_by_path(tool_calls: list[ToolCall], tracee_events: list[dict]) -> list[ToolCall]:
    """Correlate 'read' tool calls with tracee events by file path matching.

    For read tool calls, matches file/path parameter with tracee's pathname.
    This is the most precise correlation method.

    Note: read tool may use 'file' or 'path' as parameter name.
    """
    for call in tool_calls:
        if call.tool != "read":
            continue

        file_path = call.params.get("file") or call.params.get("path")
        if not file_path:
            continue

        for event in tracee_events:
            if event.get("eventName") != "security_file_open":
                continue

            pathname = extract_pathname(event)
            if not pathname or not paths_match(pathname, file_path):
                continue

            if is_system_path(pathname):
                continue

            call.tracee_events.append({
                "timestamp": event.get("timestamp"),
                "eventName": event.get("eventName"),
                "processName": event.get("processName"),
                "processId": event.get("processId"),
                "pathname": pathname,
                "eventType": "file_access",
            })

    return tool_calls


def correlate_exec_by_process_tree(
    tool_calls: list[ToolCall],
    tracee_events: list[dict],
) -> list[ToolCall]:
    """Correlate 'exec' tool calls with tracee events using process tree and argv matching.

    Algorithm:
    1. Parse execve events and build process tree
    2. Calculate match scores for each process
    3. Assign processes to tool calls based on best match
    4. Include descendant processes (shell sub-commands)
    5. Associate events for matched processes
    """
    # 1. Build process tree
    process_map = parse_execve_events(tracee_events)
    process_tree = build_process_tree(process_map)

    # 2. Extract command patterns for exec calls
    exec_calls = [(idx, call) for idx, call in enumerate(tool_calls) if call.tool == "exec"]
    call_patterns: dict[int, list[CommandPattern]] = {}
    for idx, call in exec_calls:
        command = call.params.get("command", "")
        if command:
            call_patterns[idx] = extract_process_pattern_from_command(command)

    # 3. Calculate match scores for each process
    pid_to_call: dict[int, tuple[int, int]] = {}  # pid -> (call_idx, score)
    pid_scores: dict[int, dict[int, int]] = {}  # pid -> {call_idx: score}

    for pid, info in process_map.items():
        if not info.argv:
            continue
        pid_scores[pid] = {}
        for call_idx, patterns in call_patterns.items():
            command = tool_calls[call_idx].params.get("command", "")
            score = match_score_argv(info.argv, command, info.executable_path)
            if score > 0:
                pid_scores[pid][call_idx] = score

    # 4. Assign each process to best matching tool call
    for pid, scores in pid_scores.items():
        if not scores:
            continue
        best_call_idx = max(scores, key=lambda k: scores[k])
        pid_to_call[pid] = (best_call_idx, scores[best_call_idx])

    # 5. Group PIDs by tool call
    call_to_pids: dict[int, list[tuple[int, int]]] = {}
    for pid, (call_idx, score) in pid_to_call.items():
        call_to_pids.setdefault(call_idx, []).append((pid, score))

    used_pids: set[int] = set()

    # 6. Assign events to tool calls
    for call_idx, call in exec_calls:
        command = call.params.get("command", "")
        if not command:
            continue

        # Record expected patterns
        patterns = call_patterns.get(call_idx, [])
        call.expected_patterns = [
            f"{p.process_name}" + (f" {' '.join(p.argv_prefix[1:3])}" if p.argv_prefix and len(p.argv_prefix) > 1 else "")
            for p in patterns
        ]

        matched_pids: set[int] = set()

        # Get matched processes
        for pid, score in call_to_pids.get(call_idx, []):
            if pid not in used_pids:
                matched_pids.add(pid)
                used_pids.add(pid)

        call.assigned_pids = matched_pids.copy()

        # Include descendant processes (iterate over a copy to avoid modifying set during iteration)
        pids_to_check = matched_pids.copy()
        for pid in pids_to_check:
            descendants = get_all_descendants(process_tree, pid)
            matched_pids.update(descendants)

        # Associate events
        _associate_events_to_call(call, tracee_events, matched_pids, process_map)
        used_pids.update(matched_pids)

    return tool_calls


def _associate_events_to_call(
    call: ToolCall,
    tracee_events: list[dict],
    matched_pids: set[int],
    process_map: dict[int, ProcessInfo],
) -> None:
    """Associate tracee events to a tool call for matched PIDs using dispatch table."""
    for event in tracee_events:
        pid = event.get("processId")
        if pid not in matched_pids:
            continue

        event_name = event.get("eventName")

        # Use dispatch table for event handling
        handler = EVENT_HANDLERS.get(event_name)
        if not handler:
            continue

        # Build context once
        process_info = process_map.get(pid)
        context = {
            "pid": pid,
            "argv_str": " ".join(process_info.argv) if process_info and process_info.argv else "",
            "process_name": process_info.process_name if process_info else event.get("processName", ""),
            "executable_path": process_info.executable_path if process_info else "",
        }

        handler(call, event, context)


# =============================================================================
# REPORT GENERATION
# =============================================================================

def generate_report(
    tool_calls: list[ToolCall],
    output_path: Path,
    process_map: dict[int, ProcessInfo] | None = None,
) -> dict:
    """Generate correlation report.

    Args:
        tool_calls: List of correlated tool calls.
        output_path: Output file path.
        process_map: Process ID to ProcessInfo mapping (optional, for reference).

    Returns:
        Generated report dictionary.
    """
    # Group by tool type
    tools_by_type: dict[str, list[ToolCall]] = {}
    for call in tool_calls:
        tools_by_type.setdefault(call.tool, []).append(call)

    # Calculate statistics
    total_events = sum(len(call.tracee_events) for call in tool_calls)
    calls_with_events = sum(1 for call in tool_calls if call.tracee_events)

    # Process and event type statistics
    process_stats: dict[str, dict] = {}
    event_type_stats: dict[str, int] = {}

    for call in tool_calls:
        for event in call.tracee_events:
            process_name = event.get("processName", "unknown")
            event_type = event.get("eventType", "unknown")
            process_id = event.get("processId")
            parent_process_id = event.get("parentProcessId")

            if process_name not in process_stats:
                process_stats[process_name] = {"count": 0, "pids": set(), "parent_pids": set(), "event_types": set()}
            process_stats[process_name]["count"] += 1
            if process_id:
                process_stats[process_name]["pids"].add(process_id)
            if parent_process_id is not None:
                process_stats[process_name]["parent_pids"].add(parent_process_id)
            process_stats[process_name]["event_types"].add(event.get("eventName", "unknown"))

            event_type_stats[event_type] = event_type_stats.get(event_type, 0) + 1

    # Build process summary (convert sets to lists for JSON serialization)
    process_summary = {}
    for name, stats in sorted(process_stats.items(), key=lambda x: -x[1]["count"]):
        process_summary[name] = {
            "event_count": stats["count"],
            "pids": sorted(stats["pids"]),
            "parent_pids": sorted(stats["parent_pids"]),
            "event_types": sorted(stats["event_types"]),
        }

    # Build correlation details
    correlation_details = _build_correlation_details(tool_calls)

    # Build report
    report = {
        "meta": {
            "generated_at": datetime.now().isoformat(),
            "total_tool_calls": len(tool_calls),
            "total_tracee_events": total_events,
            "calls_with_events": calls_with_events,
            "calls_without_events": len(tool_calls) - calls_with_events,
            "correlation_rate": f"{calls_with_events / len(tool_calls) * 100:.1f}%" if tool_calls else "0%",
        },
        "summary": {
            "tools_used": {tool: len(calls) for tool, calls in tools_by_type.items()},
            "correlation_success": {
                tool: sum(1 for call in calls if call.tracee_events)
                for tool, calls in tools_by_type.items()
            },
            "correlation_fail": _build_correlation_fail(tool_calls),
            "processes": process_summary,
            "event_types": dict(sorted(event_type_stats.items(), key=lambda x: -x[1])),
            "unique_processes": len(process_stats),
            "unique_pids": len(set(pid for stats in process_stats.values() for pid in stats["pids"])),
        },
        "correlation_details": correlation_details,
        "tool_calls": _build_tool_calls_summary(tool_calls),
    }

    # Write to file
    with open(output_path, "w", encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False, default=str)

    return report


def _build_correlation_details(tool_calls: list[ToolCall]) -> list[dict]:
    """Build detailed correlation info for each tool call."""
    details = []

    for idx, call in enumerate(tool_calls, 1):
        # Build command summary
        if call.tool == "exec":
            command = call.params.get("command", "")
            command_summary = command[:57] + "..." if len(command) > 60 else command
        elif call.tool == "read":
            command_summary = call.params.get("file") or call.params.get("path", "")
        else:
            command_summary = str(call.params)

        # Count event types
        file_access_count = 0
        network_connect_count = 0
        socket_create_count = 0
        dns_query_count = 0
        process_exec_count = 0
        pid_stats: dict[int, dict] = {}

        for event in call.tracee_events:
            pid = event.get("processId")
            if pid is None:
                continue

            event_type = event.get("eventType", "file_access")
            if event_type == "file_access":
                file_access_count += 1
            elif event_type == "network_connect":
                network_connect_count += 1
            elif event_type == "socket_create":
                socket_create_count += 1
            elif event_type == "dns_query":
                dns_query_count += 1
            elif event_type == "process_exec":
                process_exec_count += 1

            if pid not in pid_stats:
                pid_stats[pid] = {
                    "pid": pid,
                    "ppid": event.get("parentProcessId"),
                    "process_name": event.get("processName", "unknown"),
                    "argv": event.get("argv", ""),
                    "event_count": 0,
                    "file_access_count": 0,
                    "network_connect_count": 0,
                    "socket_create_count": 0,
                    "dns_query_count": 0,
                    "process_exec_count": 0,
                    "file_paths": set(),
                    "remote_addrs": set(),
                    "dns_queries": set(),
                    "executables": set(),
                }
            pid_stats[pid]["event_count"] += 1

            if event_type == "file_access":
                pid_stats[pid]["file_access_count"] += 1
                if event.get("pathname"):
                    pid_stats[pid]["file_paths"].add(event.get("pathname"))
            elif event_type == "network_connect":
                pid_stats[pid]["network_connect_count"] += 1
                if event.get("remote_addr"):
                    pid_stats[pid]["remote_addrs"].add(str(event.get("remote_addr")))
            elif event_type == "socket_create":
                pid_stats[pid]["socket_create_count"] += 1
            elif event_type == "dns_query":
                pid_stats[pid]["dns_query_count"] += 1
                if event.get("dns_query"):
                    pid_stats[pid]["dns_queries"].add(event.get("dns_query"))
            elif event_type == "process_exec":
                pid_stats[pid]["process_exec_count"] += 1
                if event.get("executablePath"):
                    pid_stats[pid]["executables"].add(event.get("executablePath"))

        details.append({
            "index": idx,
            "tool": call.tool,
            "command_summary": command_summary,
            "total_events": len(call.tracee_events),
            "file_access_count": file_access_count,
            "network_connect_count": network_connect_count,
            "socket_create_count": socket_create_count,
            "dns_query_count": dns_query_count,
            "process_exec_count": process_exec_count,
            "processes": [
                {
                    "pid": stats["pid"],
                    "ppid": stats["ppid"],
                    "process_name": stats["process_name"],
                    "argv": stats["argv"][:80] + "..." if len(stats["argv"]) > 80 else stats["argv"],
                    "event_count": stats["event_count"],
                    "file_access_count": stats["file_access_count"],
                    "network_connect_count": stats["network_connect_count"],
                    "dns_query_count": stats["dns_query_count"],
                    "process_exec_count": stats["process_exec_count"],
                    "file_paths": sorted(stats["file_paths"])[:20],
                    "remote_addrs": sorted(stats["remote_addrs"]),
                    "dns_queries": sorted(stats["dns_queries"]),
                    "executables": sorted(stats["executables"]),
                }
                for stats in sorted(pid_stats.values(), key=lambda x: x["pid"])
            ],
        })

    return details


def _build_correlation_fail(tool_calls: list[ToolCall]) -> dict:
    """Build diagnostic info for tool calls without events."""
    return {
        str(idx): {
            "tool": call.tool,
            "assigned_pids": list(call.assigned_pids),
            "expected_patterns": call.expected_patterns,
            "status": (
                "events_filtered_or_not_monitored"
                if call.assigned_pids
                else "no_matching_process"
            ),
            "explanation": (
                "Process assigned but events filtered (system path) or event type not monitored"
                if call.assigned_pids
                else "No matching process (correlation algorithm issue or process does not exist)"
            ),
        }
        for idx, call in enumerate(tool_calls, 1)
        if not call.tracee_events
    }


def _build_tool_calls_summary(tool_calls: list[ToolCall]) -> list[dict]:
    """Build summary list for all tool calls."""
    return [
        {
            "index": idx,
            "tool": call.tool,
            "params": {
                k: v[:200] + "..." if isinstance(v, str) and len(v) > 200 else v
                for k, v in call.params.items()
            },
            "timestamp": call.timestamp,
            "tracee_events_count": len(call.tracee_events),
            "tracee_events": call.tracee_events,
            "processes_involved": list(set(
                e.get("processName", "unknown") for e in call.tracee_events
            )),
        }
        for idx, call in enumerate(tool_calls, 1)
    ]


# =============================================================================
# PUBLIC API
# =============================================================================

def correlate_task_logs(
    task_id: str,
    transcript_path: Path,
    tracee_log_path: Path,
    output_dir: Path,
    verbose: bool = False,
) -> Path | None:
    """Correlate task logs and generate correlation analysis report.

    This is the main entry point for benchmark.py.

    Args:
        task_id: Task ID.
        transcript_path: Path to OpenClaw transcript file.
        tracee_log_path: Path to Tracee log file.
        output_dir: Output directory.
        verbose: Whether to print detailed output.

    Returns:
        Path to generated correlation report, or None if failed.
    """
    # Determine output directory
    if tracee_log_path and tracee_log_path.exists():
        task_log_dir = tracee_log_path.parent
    else:
        logger.warning("tracee_log_path does not exist, using default path")
        task_log_dir = output_dir / task_id

    task_log_dir.mkdir(parents=True, exist_ok=True)

    # Extract tool calls from transcript
    openclaw_log_path = task_log_dir / "openclaw.log"
    tool_calls = extract_tool_calls_from_transcript(transcript_path, openclaw_log_path)

    if not tool_calls:
        logger.warning("No tool calls found in transcript: %s", transcript_path)
        return None

    logger.info("Extracted %d tool calls from transcript", len(tool_calls))

    # Check tracee log
    if not tracee_log_path.exists():
        logger.warning("Tracee log does not exist: %s", tracee_log_path)
        return None

    # Parse tracee log
    tracee_events = parse_tracee_log(tracee_log_path)
    logger.info("Parsed %d tracee events", len(tracee_events))

    # Perform correlation
    tool_calls = correlate_by_path(tool_calls, tracee_events)
    tool_calls = correlate_exec_by_process_tree(tool_calls, tracee_events)

    # Generate report
    report_path = task_log_dir / "correlated.json"
    process_map = parse_execve_events(tracee_events)
    generate_report(tool_calls, report_path, process_map)

    if verbose:
        correlated = sum(1 for call in tool_calls if call.tracee_events)
        print(f"Correlation complete: {report_path}")
        print(f"  Tool calls: {len(tool_calls)}")
        print(f"  System events: {len(tracee_events)}")
        print(f"  Correlated: {correlated}/{len(tool_calls)} ({correlated/len(tool_calls)*100:.1f}%)")

    return report_path