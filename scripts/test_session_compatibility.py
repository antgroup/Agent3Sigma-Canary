"""Session/ID regressions; local runtime stand-ins, no model API calls."""

import importlib.machinery
import importlib.util
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
from types import ModuleType, SimpleNamespace
import uuid

import pytest

from test_nara_integration import ROOT, write_task
import benchmark
import lib_agent
import lib_docker
from lib_tasks import TaskLoader


def load_adapter(framework):
    relative = "nanoclaw/openclaw_openai" if framework == "nanoclaw_openai" else f"{framework}/openclaw"
    loader = importlib.machinery.SourceFileLoader(framework, str(ROOT / "workflow/images" / relative))
    module = importlib.util.module_from_spec(importlib.util.spec_from_loader(framework, loader))
    loader.exec_module(module)
    return module


def test_nara_numbers_do_not_overlap_legacy_tasks():
    tasks = TaskLoader(ROOT / "tasks").load_all_tasks()
    nara = [task for task in tasks if "NARA-Bench" in task.file_path.parts]
    legacy = [task for task in tasks if task not in nara]
    number = lambda value: int(re.match(r"task_(\d+)", value)[1])
    assert {number(task.task_id) for task in nara} == set(range(100001, 101801))
    assert {number(task.task_id) for task in legacy}.isdisjoint(number(task.task_id) for task in nara)
    for task in nara:
        assert task.file_path.stem == task.task_id
        assert number(task.task_id) == number(task.frontmatter["upstream_id"]) + 100000
    assert [task.task_id for task in benchmark._select_tasks(tasks, "23")] == ["task_23_soul_modify_direct"]
    assert [task.task_id for task in benchmark._select_tasks(tasks, "100023")] == [
        "task_100023_preview_evacuation_announcement"
    ]


@pytest.mark.parametrize("image_type", [
    "official", "official_shield", "official_secureclaw", "official_clawkeeper",
    "claude_code", "codex", "hermes", "nanoclaw", "nanoclaw_openai",
])
def test_new_session_changes_identity_and_preserves_workspace(tmp_path, monkeypatch, image_type):
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(Path, "home", classmethod(lambda cls: tmp_path / "home"))
    monkeypatch.setattr(lib_docker, "is_active", lambda: False)
    monkeypatch.setattr(lib_docker, "get_image_type", lambda: image_type)
    monkeypatch.setattr(lib_docker, "is_image_gateway_active", lambda: False)
    store = tmp_path / "agent"
    sessions = store / "sessions"
    sessions.mkdir(parents=True)
    monkeypatch.setattr(lib_docker, "ensure_transcripts_on_host", lambda *args: str(store))
    monkeypatch.setattr(lib_agent, "_get_agent_store_dir", lambda *args: store)
    task = write_task(tmp_path, directory="chain", workspace_files=[{"path": "kept.txt", "content": "fixture"}],
                      sessions=[{"prompt": "remember"}, {"prompt": "continue"},
                                {"prompt": "fresh", "new_session": True}, {"prompt": "continue fresh"}])
    native_history = {}
    calls = []

    def invoke(cmd, cwd, **kwargs):
        sid = cmd[cmd.index("--session-id") + 1]
        prompt = cmd[cmd.index("--message") + 1]
        workspace = Path(cwd)
        assert (workspace / "kept.txt").read_text() == "fixture"
        if calls:
            assert (workspace / "installed-skill.txt").read_text() == "preserved"
        (workspace / "installed-skill.txt").write_text("preserved")
        # A native runtime retains history independently of exported JSONL.
        history = native_history.setdefault(sid, [])
        calls.append((sid, prompt, list(history)))
        history.append(prompt)
        rows = [{"type": "message", "message": {"role": "user", "content": text}} for text in history]
        (sessions / f"{sid}.jsonl").write_text("".join(json.dumps(row) + "\n" for row in rows))
        return subprocess.CompletedProcess(cmd, 0, "", "")

    monkeypatch.setattr(lib_docker, "run_agent_cmd", invoke)
    workspace = tmp_path / "run/workspace"
    result = lib_agent.execute_openclaw_task(
        task=task, agent_id="bench", model_id="test/model", run_id="run", timeout_multiplier=1,
        skill_dir=tmp_path, task_agent_workspace_root=workspace.parent,
        task_agent_workspace_root_relate=workspace, local_task_agent_workspace_root_relate=workspace,
    )
    assert calls[0][0] == calls[1][0]
    assert calls[2][0] == calls[3][0] != calls[0][0]
    assert [call[2] for call in calls] == [[], ["remember"], [], ["fresh"]]
    assert [row["message"]["content"] for row in result["transcript"]] == [
        "remember", "continue", "fresh", "continue fresh"
    ]


@pytest.mark.parametrize("framework", ["claude_code", "codex", "nanoclaw", "nanoclaw_openai"])
def test_adapter_resumes_only_matching_session_ids(tmp_path, monkeypatch, framework):
    shim = load_adapter(framework)
    monkeypatch.setattr(shim, "AGENTS_DIR", tmp_path / "agents")
    monkeypatch.setattr(shim, "STATE_PATH", tmp_path / "state.json")
    monkeypatch.setattr(shim, "_load_provider_config", lambda: {})
    monkeypatch.setattr(shim, "_resolve_provider", lambda *args: dict(
        base_url="http://127.0.0.1:1", api_key="dummy", model_id="dummy", api="openai-completions",
    ))
    (tmp_path / ".git").mkdir()
    shim._save_state({"agents": {"bench": {"model": "test/model", "workspace": str(tmp_path)}}})
    if framework == "codex":
        monkeypatch.setattr(shim, "_write_codex_config", lambda *args: None)
        monkeypatch.setattr(shim, "_install_exec_policy_rules", lambda *args: None)
        monkeypatch.setattr(shim, "_rollout_path", lambda *args: None)
        monkeypatch.setattr(shim, "_codex_bin", lambda: "codex")
        monkeypatch.setattr(shim, "SKILLS_DIR", str(tmp_path))
        monkeypatch.setenv("CODEX_PERMISSION_MODE", "auto-review")
    elif framework == "claude_code":
        monkeypatch.setattr(shim, "_claude_bin", lambda: "claude")
    seen = []
    native_ids = []

    def run(cmd, **kwargs):
        env = kwargs["env"]
        if framework == "codex":
            resume = cmd[cmd.index("resume") + 1] if "resume" in cmd else None
            native = resume or str(uuid.uuid4())
            if resume:
                assert cmd.index("-s") < cmd.index("resume")
                assert cmd.index("--add-dir") < cmd.index("resume")
            stdout = "\n".join(json.dumps(row) for row in [
                {"type": "thread.started", "thread_id": native},
                {"type": "item.completed", "item": {"type": "agent_message", "text": "ok"}},
            ])
        elif framework == "claude_code":
            resume = cmd[cmd.index("--resume") + 1] if "--resume" in cmd else None
            native = resume or cmd[cmd.index("--session-id") + 1]
            stdout = json.dumps({"type": "assistant", "message": {"content": [{"type": "text", "text": "ok"}]}})
        else:
            resume = env.get("NANOCLAW_DRIVER_RESUME_SESSION")
            native = resume or str(uuid.uuid4())
            stdout = "---NANOCLAW-RESULT-BEGIN---\n" + json.dumps({
                "session_id": native, "events": [{"kind": "assistant_text", "text": "ok"}],
            }) + "\n---NANOCLAW-RESULT-END---"
        seen.append(resume)
        native_ids.append(native)
        return subprocess.CompletedProcess(cmd, 0, stdout, "")

    if framework in ("claude_code", "codex"):
        from agentcanary_runtime import ProcessResult
        def run_streamed(cmd, **kwargs):
            result = run(cmd, **kwargs)
            kwargs["on_update"](result.stdout, result.stderr)
            return ProcessResult(result.returncode, result.stdout, result.stderr, False)
        monkeypatch.setattr(shim, "run_process", run_streamed)
    else:
        monkeypatch.setattr(subprocess, "run", run)
    for sid, message in [("old", "first"), ("old", "second"), ("new", "fresh")]:
        args = SimpleNamespace(agent="bench", session_id=sid, message=message, seed_history=None, thinking=None)
        with pytest.raises(SystemExit) as result:
            shim.cmd_agent_invoke(args)
        assert result.value.code == 0
    assert seen == [None, native_ids[0], None]
    assert native_ids[0] == native_ids[1] != native_ids[2]
    if framework.startswith("nanoclaw"):
        rows = [json.loads(line) for line in (tmp_path / "agents/bench/sessions/old.jsonl").read_text().splitlines()]
        assert [row["message"]["content"][0]["text"] for row in rows if row["message"]["role"] == "user"] == ["first", "second"]
    shim.cmd_agents_delete(SimpleNamespace(id="bench"))
    assert not any(key.startswith("bench:") for key in shim._load_state().get("sessions", {}))


def test_hermes_passes_native_history_and_resets_on_new_id(tmp_path, monkeypatch):
    shim = load_adapter("hermes")
    monkeypatch.setattr(shim, "AGENTS_DIR", tmp_path / "agents")
    monkeypatch.setattr(shim, "STATE_PATH", tmp_path / "state.json")
    monkeypatch.setattr(shim, "_load_provider_config", lambda: {})
    monkeypatch.setattr(shim, "_resolve_provider", lambda *args: dict(
        base_url="http://127.0.0.1:1", api_key="dummy", model_id="dummy", api="openai-completions",
    ))
    shim._save_state({"agents": {"bench": {"model": "test/model", "workspace": str(tmp_path)}}})
    history_seen = []
    fake_runtime = ModuleType("run_agent")

    class FakeAgent:
        def __init__(self, **kwargs):
            pass

        def run_conversation(self, prompt, conversation_history):
            history_seen.append(conversation_history)
            messages = [*(conversation_history or []), {"role": "user", "content": prompt},
                        {"role": "assistant", "content": "ok " + prompt}]
            return dict(messages=messages, final_response="ok " + prompt, completed=True)

    fake_runtime.AIAgent = FakeAgent
    monkeypatch.setitem(sys.modules, "run_agent", fake_runtime)
    real_makedirs = shim.os.makedirs

    def makedirs(path, **kwargs):
        if str(path) == "/run/.shim":
            raise PermissionError("Use fallback result path in test")
        return real_makedirs(path, **kwargs)

    monkeypatch.setattr(shim.os, "makedirs", makedirs)

    def run(cmd, **kwargs):
        # Execute the actual generated driver against the fake AIAgent.
        old_path = list(sys.path)
        try:
            exec(cmd[2], {})
        finally:
            sys.path[:] = old_path
        return subprocess.CompletedProcess(cmd, 0, "", "")

    monkeypatch.setattr(subprocess, "run", run)
    first, fresh = uuid.uuid4().hex, uuid.uuid4().hex
    for sid, prompt in [(first, "one"), (first, "two"), (fresh, "fresh")]:
        with pytest.raises(SystemExit) as result:
            shim.cmd_agent_invoke(SimpleNamespace(agent="bench", session_id=sid, message=prompt, thinking=None))
        assert result.value.code == 0
    assert history_seen[0] is None and history_seen[2] is None
    assert [msg["content"] for msg in history_seen[1]] == ["one", "ok one"]
    rows = [json.loads(line) for line in (tmp_path / f"agents/bench/sessions/{first}.jsonl").read_text().splitlines()]
    assert [row["message"]["content"][0]["text"] for row in rows] == ["one", "ok one", "two", "ok two"]


@pytest.mark.parametrize("driver", ["driver.mjs", "driver_claude_openai.mjs"])
@pytest.mark.parametrize("resume", ["", "previous-native-id"])
def test_nanoclaw_sdk_drivers_roundtrip_session_id(tmp_path, driver, resume):
    if not shutil.which("node"):
        pytest.skip("Node is not installed")
    import os
    shutil.copy(ROOT / "workflow/images/nanoclaw" / driver, tmp_path / "driver.mjs")
    package = tmp_path / "node_modules/@anthropic-ai/claude-agent-sdk"
    package.mkdir(parents=True)
    (package / "package.json").write_text('{"type":"module","exports":"./index.js"}')
    (package / "index.js").write_text('''
export async function* query({ options }) {
  const expected = process.env.NANOCLAW_DRIVER_RESUME_SESSION || undefined;
  if (options.resume !== expected) throw new Error('resume option lost');
  const session_id = options.resume || 'fresh-native-id';
  yield { type: 'system', subtype: 'init', session_id };
  yield { type: 'assistant', session_id, message: { content: [{type: 'text', text: 'ok'}] } };
}
''')
    result = subprocess.run(["node", str(tmp_path / "driver.mjs")], capture_output=True, text=True, check=True,
                            env={**os.environ, "NANOCLAW_DRIVER_PROMPT": "test", "NANOCLAW_DRIVER_CWD": str(tmp_path),
                                 "NANOCLAW_DRIVER_RESUME_SESSION": resume}, timeout=10)
    payload = json.loads(result.stdout.split("---NANOCLAW-RESULT-BEGIN---\n")[1].split("\n---NANOCLAW-RESULT-END---")[0])
    assert payload == {"events": [{"kind": "assistant_text", "text": "ok"}],
                       "session_id": resume or "fresh-native-id"}


@pytest.mark.parametrize("resume", ["", "previous-native-id"])
def test_nanoclaw_opencode_driver_reuses_persisted_session(tmp_path, resume):
    if not shutil.which("node"):
        pytest.skip("Node is not installed")
    import os
    shutil.copy(ROOT / "workflow/images/nanoclaw/driver_openai.mjs", tmp_path / "driver.mjs")
    package = tmp_path / "node_modules/@opencode-ai/sdk"
    package.mkdir(parents=True)
    (package / "package.json").write_text('{"type":"module","exports":"./index.js"}')
    (package / "index.js").write_text('''
const expected = process.env.NANOCLAW_DRIVER_RESUME_SESSION || 'fresh-native-id';
let started = false;
export function createOpencodeClient() {
  return {
    event: { async subscribe() { return { stream: (async function* () {
      if (!started) throw new Error('prompt was not sent');
      yield {type: 'message.updated', properties: {info: {id:'m', role:'assistant'}}};
      yield {type: 'message.part.updated', properties: {part: {type:'text', messageID:'m', text:'ok'}}};
      yield {type: 'session.idle', properties: {sessionID:expected}};
    })() }; } },
    session: {
      async create() {
        if (process.env.NANOCLAW_DRIVER_RESUME_SESSION) throw new Error('created instead of resumed');
        return {data:{id:expected}};
      },
      async get({path}) {
        if (!process.env.NANOCLAW_DRIVER_RESUME_SESSION || path.id !== expected) throw new Error('wrong resume id');
        return {data:{id:expected}};
      },
      async promptAsync({path}) {
        if (path.id !== expected) throw new Error('wrong prompt session');
        started = true;
      },
    },
  };
}
''')
    executable = tmp_path / "opencode"
    executable.write_text('#!/usr/bin/env node\nconsole.log("opencode server listening on http://127.0.0.1:4096");\nsetInterval(() => {}, 1000);\n')
    executable.chmod(0o755)
    result = subprocess.run(["node", str(tmp_path / "driver.mjs")], capture_output=True, text=True, check=True,
                            env={**os.environ, "PATH": str(tmp_path) + os.pathsep + os.environ["PATH"],
                                 "NANOCLAW_DRIVER_PROMPT": "test", "NANOCLAW_DRIVER_CWD": str(tmp_path),
                                 "NANOCLAW_DRIVER_MODEL": "dummy", "NANOCLAW_DRIVER_BASE_URL": "http://127.0.0.1:1",
                                 "NANOCLAW_DRIVER_RESUME_SESSION": resume}, timeout=10)
    payload = json.loads(result.stdout.split("---NANOCLAW-RESULT-BEGIN---\n")[1].split("\n---NANOCLAW-RESULT-END---")[0])
    assert payload == {"events": [{"kind": "assistant_text", "text": "ok"}],
                       "session_id": resume or "fresh-native-id"}
