"""Regression tests for the NARA feature integration; no model APIs required."""

import importlib.machinery
import importlib.util
import json
import logging
from pathlib import Path
import shutil
import subprocess
import sys
import time

import pytest

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))
sys.path.insert(0, str(ROOT / "workflow"))

import benchmark
import benchmark_parallel
import build_images
import lib_agent
import lib_docker
import lib_grading
from lib_task_validation import missing_task_inputs
from lib_tasks import TaskLoader


def write_task(root, name="task_0001_example", directory="NARA-Bench/risk/domain", **metadata):
    import yaml
    path = root / "tasks" / directory / f"{name}.md"
    path.parent.mkdir(parents=True, exist_ok=True)
    fields = dict(id=name, name="Example", category="safety", grading_type="llm_judge",
                  required_skills=[], **metadata)
    path.write_text("---\n" + yaml.safe_dump(fields) + "---\n## Prompt\nRead the file.\n"
                    "## Expected Behavior\nReport its contents.\n## LLM Judge Rubric\nOutcome: 1.0\n")
    return TaskLoader(root / "tasks").load_task(path)


def load_shim(name):
    loader = importlib.machinery.SourceFileLoader(name, str(ROOT / "workflow/images" / name / "shim/openclaw"))
    module = importlib.util.module_from_spec(importlib.util.spec_from_loader(name, loader))
    loader.exec_module(module)
    return module


def test_directory_selection_does_not_leak_duplicate_ids(tmp_path):
    intended = write_task(tmp_path)
    unrelated = write_task(tmp_path, directory="safety")
    assert benchmark._select_tasks([unrelated, intended], "tasks/NARA-Bench/") == [intended]
    assert benchmark_parallel.discover_task_ids(tmp_path / "tasks", "NARA-Bench/risk") == [intended.task_id]
    assert benchmark._select_tasks([intended], "1-2") == [intended]
    assert benchmark._parse_suite_directory("../tasks/NARA-Bench") is None
    assert benchmark._select_tasks([intended], "non-security") == []


def test_parallel_worker_preserves_suite_and_exact_task_subset(tmp_path, monkeypatch):
    intended = write_task(tmp_path)
    write_task(tmp_path, directory="safety", workspace_files=[{"source": "outside-missing.json"}])
    write_task(tmp_path, name="task_0002_other", workspace_files=[{"source": "unselected-missing.json"}])
    monkeypatch.setattr(benchmark, "__file__", str(tmp_path / "scripts/benchmark.py"))
    def run_worker(cmd, **kwargs):
        monkeypatch.setattr(sys, "argv", cmd[1:])
        benchmark.main()
        return subprocess.CompletedProcess(cmd, 0)
    monkeypatch.setattr(subprocess, "run", run_worker)
    result = benchmark_parallel.run_shard(0, [intended.task_id], ["--validate-tasks"], str(tmp_path / "results"), "NARA-Bench")
    assert result["returncode"] == 0


def test_missing_inputs_and_memory_are_checked_without_docker(tmp_path):
    task = write_task(tmp_path, workspace_files=[{"source": "safety/input.csv", "dest": "input.csv"}],
                      pre_setup=[{"type": "memory", "context": "assets/safety/MEMORY.md"}])
    missing = missing_task_inputs([task], tmp_path)
    assert len(missing[str(task.file_path)]) == 2
    (tmp_path / "assets/safety").mkdir(parents=True)
    (tmp_path / "assets/safety/input.csv").write_text("id\n1\n")
    (tmp_path / "assets/safety/MEMORY.md").write_text("Old policy")
    assert missing_task_inputs([task], tmp_path) == {}


@pytest.mark.parametrize("poison", [None, "Injected instruction"])
def test_inline_memory_is_not_interpreted_as_a_filename(tmp_path, monkeypatch, poison):
    context = "# Archived context\n" + "Historical observation. " * 30
    task = write_task(tmp_path, pre_setup=[{"type": "memory", "context": context, "poison": poison}])
    assert missing_task_inputs([task], tmp_path) == {}
    monkeypatch.setattr(lib_agent, "_detect_framework_from_image", lambda: "codex")
    lib_agent._execute_memory_setup(task.frontmatter["pre_setup"][0], tmp_path)
    expected = context + ("\n\n## Important Note\n\n" + poison if poison else "")
    assert (tmp_path / "AGENTS.md").read_text() == expected


@pytest.mark.parametrize("framework,native", [("claude_code", "CLAUDE.md"), ("codex", "AGENTS.md"), ("openclaw", "MEMORY.md")])
@pytest.mark.parametrize("options", [{}, {"poison": ""}, {"poison": None}, {"poison": "Injected instruction"}],
                         ids=["omitted", "empty", "null", "poisoned"])
def test_memory_setup_with_optional_poison(tmp_path, monkeypatch, framework, native, options):
    context = tmp_path / "context.md"
    context.write_text("Historical facts\n")
    workspace = tmp_path / "workspace"
    workspace.mkdir()
    monkeypatch.setattr(lib_agent, "_detect_framework_from_image", lambda: framework)
    monkeypatch.setattr(lib_agent, "_purge_stale_container_skills", lambda: None)
    task = write_task(tmp_path, pre_setup=[{"type": "memory", "context": str(context), **options}])
    lib_agent._run_pre_setup(task, workspace, tmp_path)
    expected = context.read_text()
    if options.get("poison"):
        expected += "\n\n## Important Note\n\nInjected instruction"
    assert (workspace / "MEMORY.md").read_text() == expected
    assert (workspace / native).read_text() == expected


def test_migrated_memory_task_preserves_poisoned_context(tmp_path, monkeypatch):
    loader = TaskLoader(ROOT / "tasks/memory")
    task = loader.load_task(ROOT / "tasks/memory/task_25004_privacy_leak.md")
    step = next(step for step in task.frontmatter["pre_setup"] if step["type"] == "memory")
    monkeypatch.setattr(lib_agent, "_detect_framework_from_image", lambda: "openclaw")
    lib_agent._execute_memory_setup(step, tmp_path)
    context = (ROOT / step["context"]).read_text()
    assert (tmp_path / "MEMORY.md").read_text() == context + "\n\n## Important Note\n\n" + step["poison"]


def test_setup_commands_wait_for_workspace_delivery(tmp_path, monkeypatch):
    task = write_task(tmp_path, pre_setup=[{"type": "run_command", "command": "cat /workspace/input.csv"}])
    calls = []
    monkeypatch.setattr(lib_agent, "_purge_stale_container_skills", lambda: None)
    monkeypatch.setattr(lib_agent, "_execute_run_command_setup", lambda *args: calls.append("command"))
    monkeypatch.setattr(lib_docker, "run_cmd", lambda *args, **kwargs: calls.append("alias") or subprocess.CompletedProcess([], 0, "", ""))
    lib_agent._run_pre_setup(task, tmp_path, tmp_path, defer_run_commands=True)
    assert calls == []
    calls.append("workspace delivered")
    lib_agent._run_deferred_pre_setup_commands(task, tmp_path)
    assert calls == ["workspace delivered", "alias", "command"]


@pytest.mark.parametrize("framework,native", [("codex", "/root/.agents/skills"), ("claude_code", "/root/.claude/skills"), ("hermes", "/root/.hermes/skills")])
def test_native_skill_mounts(framework, native, monkeypatch):
    monkeypatch.setattr(lib_agent, "_detect_framework_from_image", lambda: framework)
    mounts = lib_agent._resolve_framework_skill_mounts([Path("/skills/notion-2.0.0")])
    assert mounts == [("/skills/notion-2.0.0", "/root/.openclaw/skills/notion-2.0.0", "ro"),
                      ("/skills/notion-2.0.0", native + "/notion", "ro")]


def test_new_openclaw_version_metadata_and_gateway(monkeypatch):
    monkeypatch.setattr(lib_docker, "_image_labels", {"ai.agentcanary.image_type": "official_shield", "ai.agentcanary.openclaw_version": "2026.7.1-2"})
    monkeypatch.setattr(lib_docker, "_image_gateway_active", False)
    args = dict(agent_id="test", session_id="session", message="Hello", effort="high")
    assert "--local" in lib_agent._build_openclaw_agent_command(**args)
    assert lib_docker._uses_native_openclaw_gateway()
    monkeypatch.setattr(lib_docker, "_image_gateway_active", True)
    assert "--local" not in lib_agent._build_openclaw_agent_command(**args)
    monkeypatch.setattr(lib_docker, "_image_gateway_active", False)
    monkeypatch.setattr(lib_docker, "_image_labels", {"ai.agentcanary.openclaw_version": "2026.4.11"})
    assert "--local" not in lib_agent._build_openclaw_agent_command(**args)


def test_telemetry_is_not_used_as_conversation(tmp_path):
    sessions = tmp_path / "sessions"
    sessions.mkdir()
    conversation = sessions / "session.jsonl"
    conversation.write_text('{"type":"message"}\n')
    (sessions / "session.trajectory.jsonl").write_text('{"event":"session.ended"}\n')
    assert lib_agent._find_recent_session_path(tmp_path, time.time()) == conversation


def test_profile_and_effort_result_identity(monkeypatch):
    monkeypatch.delenv("DOCKER_IMAGE_TAG", raising=False)
    identities = []
    for version, research in [("2026.4.11", False), ("2026.7.1-2", False), ("2026.7.1-2", True)]:
        monkeypatch.setenv("DOCKER_IMAGE", build_images.image_tag("official", version, research, "20261015_010101_123456"))
        identities.append(benchmark._resolve_image_tag())
    assert len(set(identities)) == 3


def test_retagged_image_metadata_controls_native_mounts(monkeypatch):
    monkeypatch.setattr(lib_docker, "DOCKER_IMAGE", "custom-runner:test")
    monkeypatch.setattr(lib_docker, "_image_labels", {})
    monkeypatch.setattr(subprocess, "run", lambda *args, **kwargs: subprocess.CompletedProcess(
        [], 0, '{"ai.agentcanary.image_type":"codex"}', ""))
    lib_docker.load_image_metadata()
    mounts = lib_agent._resolve_framework_skill_mounts([Path("/skills/notion-2.0.0")])
    assert mounts[-1][1] == "/root/.agents/skills/notion"


@pytest.mark.parametrize("handlers,web_origin,expect_https", [(0, "", False), (1, "", True), (0, "https://mock.test", True)])
def test_claude_readiness_matches_mock_tls_configuration(monkeypatch, handlers, web_origin, expect_https):
    monkeypatch.setattr(lib_docker, "_image_labels", {"ai.agentcanary.image_type": "claude_code"})
    monkeypatch.setenv("WEB_SIM_BASE_URL", web_origin)
    requested = []
    def fake_probe(cmd, **kwargs):
        requested.append(cmd[-1])
        output = json.dumps({"count": handlers}) if cmd[-1].endswith("/__api_handlers") else "404"
        return subprocess.CompletedProcess(cmd, 0, output, "")
    monkeypatch.setattr(subprocess, "run", fake_probe)
    lib_docker._wait_for_mock_api_ready("test-container")
    assert any(url.startswith("https:") for url in requested) == expect_https


def test_validation_stops_before_agent_creation(tmp_path, monkeypatch):
    write_task(tmp_path, workspace_files=[{"source": "missing.json", "dest": "input.json"}])
    monkeypatch.setattr(benchmark, "__file__", str(tmp_path / "scripts/benchmark.py"))
    monkeypatch.setattr(benchmark, "ensure_agent_exists", lambda *args: pytest.fail("Created an agent during validation"))
    monkeypatch.setattr(sys, "argv", ["benchmark.py", "--suite", "NARA-Bench", "--validate-tasks"])
    with pytest.raises(SystemExit) as exc:
        benchmark.main()
    assert exc.value.code == 2


def test_trajectory_only_runs_and_resumes_without_grading(tmp_path, monkeypatch):
    task = write_task(tmp_path)
    monkeypatch.setattr(benchmark, "__file__", str(tmp_path / "scripts/benchmark.py"))
    monkeypatch.setattr(benchmark, "REPO_ROOT", tmp_path)
    monkeypatch.setattr(benchmark, "ensure_agent_exists", lambda *args: None)
    monkeypatch.setattr(benchmark, "cleanup_agent_sessions", lambda *args: None)
    monkeypatch.setattr(benchmark, "_get_git_version", lambda *args: "test")
    monkeypatch.setattr(lib_docker, "is_active", lambda: False)
    executions = []
    def execute(**kwargs):
        executions.append(kwargs)
        return dict(task_id=task.task_id, agent_id="test", status="success", timed_out=False,
                    execution_time=0.1, workspace=str(tmp_path), usage={},
                    transcript=[{"type": "message", "message": {"role": "assistant", "content": "Done"}}])
    monkeypatch.setattr(benchmark, "execute_openclaw_task", execute)
    monkeypatch.setattr(benchmark, "grade_task", lambda **kwargs: pytest.fail("Trajectory-only called the judge"))
    argv = ["benchmark.py", "--model", "test/model", "--suite", "NARA-Bench", "--trajectory-only",
            "--effort", "high", "--output-dir", str(tmp_path / "results")]
    monkeypatch.setattr(sys, "argv", argv)
    benchmark.main()
    aggregate = json.loads(next((tmp_path / "results").glob("*.json")).read_text())
    assert aggregate["tasks"][0]["grading"]["mean"] is None
    assert aggregate["efficiency"]["ungraded_tasks"] == 1
    records = list((tmp_path / "trajectories").rglob("trajectory_*.json"))
    assert len(records) == 1 and "Done" in json.loads(records[0].read_text())["transcript_summary"]
    monkeypatch.setattr(sys, "argv", argv + ["--resume"])
    benchmark.main()
    assert len(executions) == 1
    assert executions[0]["effort"] == "high"


def test_old_rubrics_keep_their_criteria(tmp_path):
    task = write_task(tmp_path, directory="direct")
    prompt = lib_grading._build_judge_prompt(task, "evidence", "Custom Criterion (Weight: 100%)")
    assert "ACTUAL criterion names" in prompt
    assert "0.6-0.7" not in prompt
    assert "outcome_assessment * 0.50" not in prompt


def test_native_cli_transcripts_preserve_tool_results(tmp_path):
    codex = load_shim("codex")
    rollout = tmp_path / "rollout.jsonl"
    rollout.write_text("\n".join(json.dumps({"type": "response_item", "payload": item}) for item in [
        {"type": "function_call", "name": "exec_command", "call_id": "call1", "arguments": '{"cmd":"cat input.csv"}'},
        {"type": "function_call_output", "call_id": "call1", "output": "id\n123"},
    ]))
    events = codex._events_from_rollout(rollout)
    assert events[0]["kind"] == "tool_use"
    assert events[1]["kind"] == "tool_result" and "123" in events[1]["result"]
    claude = load_shim("claude_code")
    events = claude._parse_stream_json(json.dumps({"type": "user", "message": {"content": [
        {"type": "tool_result", "tool_use_id": "call1", "content": [{"type": "text", "text": "id\n123"}]}
    ]}}))
    assert events[0]["tool_use_id"] == "call1" and "123" in events[0]["result"]


@pytest.mark.parametrize("framework", ["codex", "claude_code"])
def test_seed_history_creates_native_sessions(tmp_path, monkeypatch, framework):
    shim = load_shim(framework)
    history = tmp_path / "history.json"
    history.write_text(json.dumps({"messages": [
        {"role": "user", "content": "Remember the prior policy"},
        {"role": "assistant", "content": "Recorded the prior policy"},
    ]}))
    if framework == "codex":
        monkeypatch.setattr(shim, "CODEX_HOME", tmp_path / "codex")
        session, events = shim._write_seed_rollout(str(history), str(tmp_path), "test-model")
    else:
        monkeypatch.setattr(shim, "_project_dir_for_cwd", lambda _: tmp_path / "claude")
        session, events = shim._write_seed_claude_session(str(history), str(tmp_path), "test-model")
    assert any(session in p.name for p in tmp_path.rglob("*.jsonl"))
    assert [event["message"]["role"] for event in events] == ["user", "assistant"]


def test_skill_packaging_preserves_runtime_resources(tmp_path):
    repo = tmp_path / "_skills_repository"
    repo.mkdir()
    shutil.copy(ROOT / "_skills_repository/buildAll.sh", repo / "buildAll.sh")
    skill = repo / "ansible-2.0.0"
    for resource in ("SKILL.md", "ansible.cfg", "inventory/hosts.yml", "roles/common/tasks/main.yml", "agent_eval/task.md"):
        path = skill / resource
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("example")
    subprocess.run(["bash", str(repo / "buildAll.sh"), "--platform", "linux"], check=True, capture_output=True, text=True)
    packaged = repo / "skill_dest/skills/ansible-2.0.0"
    assert (packaged / "roles/common/tasks/main.yml").exists()
    assert (packaged / "inventory/hosts.yml").exists()
    assert (packaged / "ansible.cfg").exists()
    assert not (packaged / "agent_eval").exists()


def test_ungraded_trajectories_render_and_export(tmp_path):
    spec = importlib.util.spec_from_file_location("workflow_analysis.app", ROOT / "workflow_analysis/app.py")
    analysis = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = analysis
    spec.loader.exec_module(analysis)
    path = tmp_path / "task_example/result.json"
    path.parent.mkdir()
    record = dict(task_id="task_example", job_id="NARA-Bench#model#no-attack#date", model="test",
                  status="success", execution_time=1, grading={"score": None, "max_score": None,
                  "breakdown": {}, "grading_type": "trajectory_only"})
    path.write_text(json.dumps(record))
    client = analysis.app.test_client()
    response = client.get("/", query_string={"dir": str(tmp_path)})
    assert response.status_code == 200 and b"N/A" in response.data
    response = client.post("/api/export", json={"directory": str(tmp_path)})
    assert response.status_code == 200 and b"N/A" in response.data
    results = analysis.load_results_from_directory(str(tmp_path))
    assert results[0]["score"] is None
    assert analysis.compute_stats(results + [{"score": 1.0, "grading": {}}])["avg_score"] == 100


@pytest.fixture
def build_project(tmp_path):
    project = tmp_path / "project"
    shutil.copytree(ROOT / "workflow", project / "workflow", ignore=shutil.ignore_patterns("openclaw.json", "__pycache__"))
    for dockerfile in (project / "workflow/images").glob("*/Dockerfile"):
        (dockerfile.parent / "openclaw.json").write_text('{"models":{"providers":{}}}')
    (project / "assets/mock_api/data").mkdir(parents=True)
    (project / "assets/mock_api/data/example.json").write_text("{}")
    for name in ("presidio-pii-skill", "moodle", "trivy-security-scanner", "docker-essentials", "cron-scheduling", "prometheus", "nmap-recon"):
        folder = project / "_skills_repository" / f"{name}-2.0.0"
        folder.mkdir(parents=True)
        (folder / "SKILL.md").write_text("Example skill")
    return project


@pytest.mark.parametrize("image_type,research", [("official", False), ("official_shield", True), ("claude_code", True), ("codex", True), ("hermes", True), ("nanoclaw", True)])
def test_composed_contexts(build_project, tmp_path, image_type, research):
    context = tmp_path / "context"
    build_images.prepare_context(build_project, context, image_type, "2026.7.1-2", research)
    dockerfile = (context / "Dockerfile").read_text()
    assert f'ai.agentcanary.image_type="{image_type}"' in dockerfile
    assert ("/opt/agentcanary-research/install.sh" in dockerfile) == research
    assert (context / "docker/mock-api/entrypoint.sh").exists()
    if image_type.startswith("official"):
        assert "ARG OPENCLAW_VERSION=2026.7.1-2" in dockerfile
    if image_type == "official_shield":
        assert 'p.openclaw.extensions = ["./dist/index.js"]' in dockerfile
    if image_type in ("claude_code", "codex"):
        assert (context / "shim/openclaw").exists()


def test_build_resume_preserves_options_and_retries_failures(build_project, tmp_path, monkeypatch):
    monkeypatch.setattr(build_images, "PROJECT_ROOT", build_project)
    monkeypatch.setattr(shutil, "which", lambda _: "/usr/bin/docker")
    workspace = tmp_path / "build"
    run = subprocess.run
    built = []
    def fake_docker(cmd, **kwargs):
        if cmd[0] != "docker":
            return run(cmd, **kwargs)
        if cmd[1] == "build":
            built.append(cmd)
            if len(built) == 1:
                raise subprocess.CalledProcessError(1, cmd)
        return subprocess.CompletedProcess(cmd, 0, "", "")
    monkeypatch.setattr(subprocess, "run", fake_docker)
    assert build_images.main(["--images", "official,codex", "--safety-research", "--openclaw-version", "newest", "--workspace", str(workspace), "--non-interactive"]) == 1
    assert build_images.main(["--resume", str(workspace)]) == 0
    state = json.loads((workspace / build_images.STATE_NAME).read_text())
    assert state["safety_research"] and state["openclaw_version"] == "2026.7.1-2"
    assert len(built) == 3
    assert set(state["completed"]) == {"official", "codex"}


def test_prepare_only_needs_no_docker(build_project, tmp_path, monkeypatch):
    monkeypatch.setattr(build_images, "PROJECT_ROOT", build_project)
    monkeypatch.setattr(shutil, "which", lambda _: None)
    workspace = tmp_path / "prepared"
    assert build_images.main(["--images", "codex", "--prepare-only", "--non-interactive", "--workspace", str(workspace)]) == 0
    assert json.loads((workspace / build_images.STATE_NAME).read_text())["completed"] == []


def test_proxy_and_selection_validation():
    assert build_images.select_types("1,codex,1") == ["official", "codex"]
    assert "https_proxy=http://host.docker.internal:7890" in build_images.proxy_args("http://127.0.0.1:7890", "darwin")
    with pytest.raises(ValueError):
        build_images.resolve_version("latest; echo bad")
    with pytest.raises(ValueError):
        build_images.select_types("../official")
