"""Deadline/trajectory regressions using real local processes, never model APIs."""

import json
import os
from pathlib import Path
import subprocess
import sys
import time
from types import SimpleNamespace

import pytest

from test_nara_integration import ROOT, load_shim, write_task
import agentcanary_runtime as runtime
import lib_agent
import lib_docker


def messages(path):
    return [row["message"] for row in runtime.read_jsonl(path) if row.get("type") == "message"]


def texts(path, role):
    return [msg["content"][0]["text"] for msg in messages(path) if msg["role"] == role]


def assert_stopped(pid):
    path = Path(f"/proc/{pid}/stat")
    assert not path.exists() or path.read_text().rsplit(") ", 1)[1].split()[0] == "Z"


@pytest.mark.parametrize("deadline_source", ["shim", "caller"])
@pytest.mark.parametrize("family", ["claude_code", "codex"])
def test_native_timeout_saves_partial_trace_and_nonzero_status(tmp_path, monkeypatch, family, deadline_source):
    shim, invoke, cli = configure_adapter(tmp_path, monkeypatch, family)
    monkeypatch.setenv("FAKE_WAIT", "30")
    monkeypatch.setenv("SHIM_TIMEOUT_SECONDS", "0.7" if deadline_source == "shim" else "30")
    if deadline_source == "caller":
        monkeypatch.setenv("AGENTCANARY_DEADLINE_EPOCH", str(time.time() + .7))
    assert invoke("session", "a prompt") == 124
    canonical = list((tmp_path / "agents/bench/sessions").glob("*.jsonl"))
    assert len(canonical) == 1
    assert texts(canonical[0], "assistant") == ["partial answer"]
    assert texts(canonical[0], "user") == ["a prompt"]
    logs = list((tmp_path / "agents/bench/sessions/runtime").glob("*/attempt-*/stdout.log"))
    assert len(logs) == 1  # Never retry a timed out invocation.
    assert "partial answer" in logs[0].read_text() or family == "codex"
    assert_stopped(int((tmp_path / "native.pid").read_text()))


def configure_adapter(tmp_path, monkeypatch, family):
    shim = load_shim(family)
    monkeypatch.setattr(shim, "AGENTS_DIR", tmp_path / "agents")
    monkeypatch.setattr(shim, "STATE_PATH", tmp_path / "state.json")
    monkeypatch.setattr(shim, "SKILLS_DIR", str(tmp_path / "skills"))
    monkeypatch.setattr(shim, "_load_provider_config", lambda: {})
    monkeypatch.setattr(shim, "_resolve_provider", lambda *args: dict(
        base_url="http://127.0.0.1:1", api_key="dummy", model_id="dummy"))
    (tmp_path / ".git").mkdir()
    shim._save_state({"agents": {"bench": {"model": "test/model", "workspace": str(tmp_path)}}})
    cli = tmp_path / "fake-cli"
    cli.write_text(f"#!{sys.executable}\n" + '''
import json, os, sys, time
from pathlib import Path
Path('native.pid').write_text(str(os.getpid()))
if os.environ['FAKE_FAMILY'] == 'codex':
    root = Path(os.environ['FAKE_CODEX_HOME']) / 'sessions'
    root.mkdir(parents=True, exist_ok=True)
    sid = sys.argv[sys.argv.index('resume') + 1] if 'resume' in sys.argv else 'native-1'
    existing = list(root.rglob('*' + sid + '.jsonl'))
    path = existing[0] if existing else root / ('rollout-' + sid + '.jsonl')
    with path.open('a') as out:
        for role, text in [('user', sys.argv[-1]), ('assistant', 'partial answer')]:
            out.write(json.dumps({'type':'response_item', 'payload':{'type':'message', 'role':role,
                'content':[{'type':'input_text' if role == 'user' else 'output_text', 'text':text}]}}) + '\\n')
    print(json.dumps({'type':'thread.started', 'thread_id':sid}), flush=True)
else:
    print(json.dumps({'type':'assistant', 'message':{'content':[{'type':'text', 'text':'partial answer'}]}}), flush=True)
time.sleep(float(os.environ.get('FAKE_WAIT', '0')))
''')
    cli.chmod(0o755)
    monkeypatch.setenv("FAKE_FAMILY", family)
    monkeypatch.delenv("AGENTCANARY_DEADLINE_EPOCH", raising=False)
    monkeypatch.setenv("SHIM_TIMEOUT_SECONDS", "10")
    if family == "codex":
        monkeypatch.setattr(shim, "CODEX_HOME", tmp_path / "codex-home")
        monkeypatch.setenv("FAKE_CODEX_HOME", str(shim.CODEX_HOME))
        monkeypatch.setattr(shim, "_write_codex_config", lambda *args: None)
        monkeypatch.setattr(shim, "_install_exec_policy_rules", lambda *args: None)
        monkeypatch.setattr(shim, "_codex_bin", lambda: str(cli))
    else:
        monkeypatch.setattr(shim, "_claude_bin", lambda: str(cli))

    def invoke(session, prompt, seed=None):
        args = SimpleNamespace(agent="bench", session_id=session, message=prompt, seed_history=seed, thinking=None)
        with pytest.raises(SystemExit) as outcome:
            shim.cmd_agent_invoke(args)
        return outcome.value.code
    return shim, invoke, cli


def test_codex_full_rollout_replaces_export_preserving_real_repetitions(tmp_path, monkeypatch):
    shim, invoke, _ = configure_adapter(tmp_path, monkeypatch, "codex")
    seed = tmp_path / "seed.json"
    seed.write_text(json.dumps([{"role": "user", "content": "seed"}, {"role": "assistant", "content": "seed answer"}]))
    assert invoke("seeded", "repeat", str(seed)) == 0
    assert invoke("seeded", "repeat") == 0
    path = tmp_path / "agents/bench/sessions/seeded.jsonl"
    assert texts(path, "user") == ["seed", "repeat", "repeat"]
    assert texts(path, "assistant") == ["seed answer", "partial answer", "partial answer"]
    # Polling, then another turn, must not append the already exported rollout.
    assert invoke("seeded", "third") == 0
    assert texts(path, "user") == ["seed", "repeat", "repeat", "third"]
    assert len(texts(path, "assistant")) == 4


@pytest.mark.parametrize("family", ["claude_code", "codex"])
def test_stream_fallback_publishes_each_turn_once(tmp_path, monkeypatch, family):
    shim, invoke, cli = configure_adapter(tmp_path, monkeypatch, family)
    if family == "codex":
        monkeypatch.setattr(shim, "_rollout_path", lambda *args: None)
        cli.write_text(f"#!{sys.executable}\nimport json, time\n" +
                       "print(json.dumps({'type':'thread.started','thread_id':'native'}), flush=True)\n" +
                       "print(json.dumps({'type':'item.completed','item':{'type':'agent_message','text':'answer'}}), flush=True)\n" +
                       "time.sleep(.5)\n")
    else:
        monkeypatch.setenv("FAKE_WAIT", ".5")
    assert invoke("same", "repeat") == 0
    assert invoke("same", "repeat") == 0
    canonical = list((tmp_path / "agents/bench/sessions").glob("*.jsonl"))
    assert len(canonical) == 1
    assert texts(canonical[0], "user") == ["repeat", "repeat"]
    assert len(texts(canonical[0], "assistant")) == 2


def test_supervisor_stops_detached_descendants_and_keeps_output(tmp_path, monkeypatch):
    monkeypatch.setattr(lib_docker, "_container_id", None)
    child_code = "import signal,time;signal.signal(signal.SIGTERM,signal.SIG_IGN);time.sleep(60)"
    parent_code = ("import subprocess,sys,time;from pathlib import Path;"
                   f"p=subprocess.Popen([sys.executable,'-c',{child_code!r}],start_new_session=True);"
                   f"Path({str(tmp_path / 'pid')!r}).write_text(str(p.pid));"
                   "print('already generated',flush=True);time.sleep(60)")
    started = time.monotonic()
    with pytest.raises(subprocess.TimeoutExpired) as outcome:
        lib_docker.run_agent_cmd([sys.executable, "-u", "-c", parent_code], timeout=.7)
    assert "already generated" in outcome.value.stdout
    assert time.monotonic() - started < 5
    assert_stopped(int((tmp_path / "pid").read_text()))


def test_stream_is_persisted_before_process_finishes(tmp_path):
    observed = []
    def update(stdout, stderr):
        if stdout:
            assert not (tmp_path / "done").exists()
            observed.append(stdout)
    code = f"import time;from pathlib import Path;print('partial',flush=True);time.sleep(30);Path({str(tmp_path / 'done')!r}).touch()"
    result = runtime.run_process([sys.executable, "-c", code], cwd=None, env=os.environ.copy(),
                                 deadline=time.monotonic() + .7, log_dir=tmp_path, on_update=update)
    assert result.returncode == 124 and result.timed_out
    assert observed and (tmp_path / "stdout.log").read_text() == "partial\n"


def test_transport_timeout_cancels_inside_container_before_returning(monkeypatch):
    calls = []
    def run(cmd, **kwargs):
        calls.append(cmd)
        raise subprocess.TimeoutExpired(cmd, 1, output="original" if len(calls) == 1 else "cleanup")
    monkeypatch.setattr(lib_docker, "run_cmd", run)
    monkeypatch.setattr(lib_docker, "_stop_gateway_after_timeout", lambda: calls.append(["stop-gateway"]))
    with pytest.raises(subprocess.TimeoutExpired) as outcome:
        lib_docker.run_agent_cmd(["openclaw", "agent"], timeout=1)
    assert outcome.value.stdout == "original"
    assert calls[0][4] == "supervise" and calls[1][3] == "cancel"
    assert calls[0][5] == calls[1][4]  # Same process control file, not a broad pkill.
    assert calls[2] == ["stop-gateway"]


@pytest.mark.parametrize("mode", ["single", "warmup", "isolated", "empty", "new_session", "empty_new_session"])
def test_harness_keeps_timeout_status_and_partial_transcript(tmp_path, monkeypatch, mode):
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(Path, "home", classmethod(lambda cls: tmp_path / "home"))
    monkeypatch.setattr(lib_docker, "is_active", lambda: False)
    monkeypatch.setattr(lib_docker, "uses_native_openclaw", lambda: False)
    monkeypatch.setattr(lib_agent, "_detect_framework_from_image", lambda: "openclaw")
    monkeypatch.setattr(lib_agent, "_get_agent_store_dir", lambda *args: tmp_path / "unused-agent-store")
    monkeypatch.setattr(lib_agent, "cleanup_agent_sessions_in_container", lambda *args: None)
    monkeypatch.setattr(lib_docker, "ensure_transcripts_on_host", lambda agent, *args: str(tmp_path / agent))
    metadata = {"timeout_seconds": 30}
    if mode == "warmup":
        metadata["pre_setup"] = [{"type": "warmup_prompt", "message": "warmup"}]
    elif mode == "isolated":
        metadata.update(isolate_session_guard=True, sessions=["first", "second"])
    elif mode in ("new_session", "empty_new_session"):
        metadata["sessions"] = ["first", {"prompt": "second", "new_session": True}]
    task = write_task(tmp_path, **metadata)
    calls = []
    def run(cmd, **kwargs):
        calls.append(cmd)
        assert 0 < kwargs["timeout"] <= 30
        sid = cmd[cmd.index("--session-id") + 1]
        agent = cmd[cmd.index("--agent") + 1]
        prompt = cmd[cmd.index("--message") + 1]
        if mode != "empty" and not (mode == "empty_new_session" and len(calls) == 2):
            runtime.atomic_text(tmp_path / agent / "sessions" / f"{sid}.jsonl", json.dumps(
                {"type": "message", "message": {"role": "user", "content": prompt}}) + "\n")
        if mode in ("new_session", "empty_new_session") and len(calls) == 1:
            return subprocess.CompletedProcess(cmd, 0, "", "")
        raise subprocess.TimeoutExpired(cmd, kwargs["timeout"], output="partial", stderr="deadline")
    monkeypatch.setattr(lib_docker, "run_agent_cmd", run)
    workspace = tmp_path / "run/workspace"
    result = lib_agent.execute_openclaw_task(
        task=task, agent_id="bench", model_id="test/model", run_id="run", timeout_multiplier=1,
        skill_dir=tmp_path, task_agent_workspace_root=workspace.parent,
        task_agent_workspace_root_relate=workspace, local_task_agent_workspace_root_relate=workspace)
    assert result["status"] == "timeout" and result["timed_out"] and result["exit_code"] == 124
    assert len(calls) == (2 if mode in ("new_session", "empty_new_session") else 1)
    assert len(result["transcript"]) == (0 if mode == "empty" else 2 if mode == "new_session" else 1)


def test_long_tool_output_and_call_identity_are_preserved(tmp_path, monkeypatch):
    shim = load_shim("codex")
    monkeypatch.setattr(shim, "AGENTS_DIR", tmp_path)
    long_output = "result" * 3000
    path = shim._write_minimal_transcript("bench", "session", "ignored", [
        {"kind": "tool_use", "id": "call-1", "name": "exec_command", "arguments": {"cmd": "pwd"}},
        {"kind": "tool_result", "tool_use_id": "call-1", "result": long_output},
    ], snapshot=True)
    call, output = messages(path)
    assert call["content"][0]["id"] == output["toolCallId"] == "call-1"
    assert output["content"][0]["text"] == long_output


@pytest.mark.parametrize("family", ["claude_code", "codex"])
def test_retry_uses_original_deadline_and_keeps_second_attempt_output(tmp_path, monkeypatch, family):
    shim, invoke, cli = configure_adapter(tmp_path, monkeypatch, family)
    payload = ({"type": "assistant", "message": {"content": [{"type": "text", "text": "retry output"}]}}
               if family == "claude_code" else
               {"type": "item.completed", "item": {"type": "agent_message", "text": "retry output"}})
    cli.write_text(f"#!{sys.executable}\n" + '''
import time, sys
from pathlib import Path
marker = Path('first-attempt')
if not marker.exists():
    marker.touch()
    time.sleep(.8)
    sys.exit(1)
''' + f"print({json.dumps(payload)!r}, flush=True)\ntime.sleep(30)\n")
    monkeypatch.setenv("SHIM_TIMEOUT_SECONDS", "1.2")
    start = time.monotonic()
    assert invoke("session", "prompt") == 124
    assert time.monotonic() - start < 1.9
    sessions = tmp_path / "agents/bench/sessions"
    assert len(list(sessions.glob("runtime/*/attempt-*/stdout.log"))) == 2
    assert texts(next(sessions.glob("*.jsonl")), "assistant") == ["retry output"]


def test_warmup_consumes_single_turn_task_budget(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(Path, "home", classmethod(lambda cls: tmp_path / "home"))
    monkeypatch.setattr(lib_docker, "is_active", lambda: False)
    monkeypatch.setattr(lib_docker, "uses_native_openclaw", lambda: False)
    monkeypatch.setattr(lib_agent, "_detect_framework_from_image", lambda: "openclaw")
    monkeypatch.setattr(lib_agent, "cleanup_agent_sessions", lambda *args: None)
    monkeypatch.setattr(lib_docker, "ensure_transcripts_on_host", lambda *args: str(tmp_path / "bench"))
    clock = [100.0]
    monkeypatch.setattr(lib_agent.time, "monotonic", lambda: clock[0])
    budgets = []
    def run(cmd, **kwargs):
        budgets.append(kwargs["timeout"])
        clock[0] += 10
        sid = cmd[cmd.index("--session-id") + 1]
        runtime.atomic_text(tmp_path / "bench/sessions" / f"{sid}.jsonl", json.dumps(
            {"type": "message", "message": {"role": "assistant", "content": "ok"}}) + "\n")
        return subprocess.CompletedProcess(cmd, 0, "", "")
    monkeypatch.setattr(lib_docker, "run_agent_cmd", run)
    task = write_task(tmp_path, timeout_seconds=30, pre_setup=[{"type": "warmup_prompt", "message": "warmup"}])
    workspace = tmp_path / "run/workspace"
    result = lib_agent.execute_openclaw_task(
        task=task, agent_id="bench", model_id="test/model", run_id="run", timeout_multiplier=1,
        skill_dir=tmp_path, task_agent_workspace_root=workspace.parent,
        task_agent_workspace_root_relate=workspace, local_task_agent_workspace_root_relate=workspace)
    assert result["status"] == "success"
    assert budgets == [30, 20]
