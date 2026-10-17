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
import generate_config
import lib_agent
import lib_docker
import lib_grading
from lib_task_validation import missing_task_inputs, validate_task_toolsets
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
    loader = importlib.machinery.SourceFileLoader(name, str(ROOT / "workflow/images" / name / "openclaw"))
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


@pytest.mark.parametrize("metadata", [{}, {"required_toolset": None}, {"required_toolset": ""}, {"required_toolset": "  "}])
@pytest.mark.parametrize("docker_mode", [False, True])
def test_empty_toolset_preserves_legacy_runtime_choices(tmp_path, metadata, docker_mode):
    task = write_task(tmp_path, **metadata)
    validate_task_toolsets([task], "custom-base:latest", docker_mode=docker_mode)


@pytest.mark.parametrize("value", [True, [], {}, ["safety_research"], "safety", "unknown"])
def test_invalid_toolset_is_rejected_even_in_input_validation(tmp_path, value):
    task = write_task(tmp_path, required_toolset=value)
    with pytest.raises(ValueError, match="required_toolset"):
        validate_task_toolsets([task], "", docker_mode=False, check_runtime=False)


@pytest.mark.parametrize("image_type", build_images.IMAGE_TYPES)
def test_generated_image_names_enforce_toolset_contract(tmp_path, image_type):
    task = write_task(tmp_path, required_toolset="safety_research")
    image = build_images.image_tag(image_type, True, "20261016_120000")
    assert "-safety_research-" in image
    validate_task_toolsets([task], image, docker_mode=True)
    base = build_images.image_tag(image_type, False, "20261016_120000")
    with pytest.raises(ValueError, match="DOCKER_IMAGE"):
        validate_task_toolsets([task], base, docker_mode=True)


@pytest.mark.parametrize("image,valid", [
    ("openclaw-official_newest_safety_research-v20261016", True),
    ("registry.example:5000/team/codex:safety_research", True),
    ("registry.example/team/codex-safety_research@sha256:abc", True),
    ("safety_research.example/team/codex:base", False),
    ("registry.example/safety_research/codex:base", False),
    ("codex-safety_researcher:latest", False),
    ("codex-unsafety_research:latest", False),
    ("", False),
])
def test_toolset_marker_belongs_to_the_image_name_or_tag(tmp_path, image, valid):
    task = write_task(tmp_path, required_toolset="safety_research")
    if valid:
        validate_task_toolsets([task], image, docker_mode=True)
    else:
        with pytest.raises(ValueError, match="DOCKER_IMAGE"):
            validate_task_toolsets([task], image, docker_mode=True)


@pytest.mark.parametrize("flags", [[], ["--docker"], ["--docker", "--validate-tasks"]])
def test_benchmark_rejects_toolset_mismatch_before_preparation(tmp_path, monkeypatch, caplog, flags):
    task = write_task(tmp_path, required_toolset="safety_research")
    monkeypatch.setattr(benchmark, "__file__", str(tmp_path / "scripts/benchmark.py"))
    monkeypatch.setattr(lib_docker, "DOCKER_IMAGE", "openclaw-claude_code-base:latest")
    monkeypatch.setattr(benchmark, "missing_task_inputs", lambda *args: pytest.fail("Should reject before input checks or runtime setup"))
    output = tmp_path / "results"
    monkeypatch.setattr(sys, "argv", ["benchmark.py", "--model", "test/model", "--suite", "NARA-Bench",
                                     "--output-dir", str(output), *flags])
    with pytest.raises(SystemExit) as error:
        benchmark.main()
    assert error.value.code == 2
    assert task.task_id in caplog.text and "--safety-research" in caplog.text
    assert not output.exists()


def test_input_only_validation_does_not_require_a_docker_image(tmp_path, monkeypatch):
    write_task(tmp_path, required_toolset="safety_research")
    monkeypatch.setattr(benchmark, "__file__", str(tmp_path / "scripts/benchmark.py"))
    monkeypatch.setattr(lib_docker, "DOCKER_IMAGE", "base:latest")
    monkeypatch.setattr(sys, "argv", ["benchmark.py", "--suite", "NARA-Bench", "--validate-tasks"])
    benchmark.main()


@pytest.mark.parametrize("selection", [[], ["--task-ids", ""], ["--task-ids="]])
def test_parallel_rejects_mixed_suite_before_spawning_any_worker(tmp_path, monkeypatch, caplog, selection):
    write_task(tmp_path, name="task_0001_legacy")
    required = write_task(tmp_path, name="task_0002_research", required_toolset="safety_research")
    monkeypatch.setattr(benchmark_parallel, "SCRIPT_DIR", tmp_path / "scripts")
    monkeypatch.setattr(lib_docker, "DOCKER_IMAGE", "openclaw-codex-base:latest")
    monkeypatch.setattr(benchmark_parallel, "run_shard", lambda *args: pytest.fail("No worker should start"))
    monkeypatch.setattr(benchmark_parallel, "ProcessPoolExecutor", lambda **kwargs: pytest.fail("No pool should start"))
    monkeypatch.setattr(sys, "argv", ["benchmark_parallel.py", "--workers", "2", "--model", "test/model",
                                     "--suite", "NARA-Bench", "--docker", *selection])
    with pytest.raises(SystemExit) as error:
        benchmark_parallel.main()
    assert error.value.code == 2
    assert required.task_id in caplog.text and "DOCKER_IMAGE" in caplog.text


@pytest.mark.parametrize("runner", ["serial", "parallel"])
@pytest.mark.parametrize("joined", [False, True])
def test_toolset_check_respects_exact_task_selection(tmp_path, monkeypatch, runner, joined):
    old = write_task(tmp_path, name="task_0001_legacy")
    write_task(tmp_path, name="task_0002_research", required_toolset="safety_research")
    monkeypatch.setattr(lib_docker, "DOCKER_IMAGE", "openclaw-codex-base:latest")
    selection = [f"--task-ids={old.task_id}"] if joined else ["--task-ids", old.task_id]
    monkeypatch.setattr(sys, "argv", ["benchmark.py", "--suite", "NARA-Bench", "--validate-tasks", "--docker", *selection])
    if runner == "serial":
        monkeypatch.setattr(benchmark, "__file__", str(tmp_path / "scripts/benchmark.py"))
        benchmark.main()
    else:
        monkeypatch.setattr(benchmark_parallel, "SCRIPT_DIR", tmp_path / "scripts")
        monkeypatch.setattr(sys, "argv", [*sys.argv, "--workers", "1"])
        def run_shard(index, task_ids, extra_args, output_dir, suite):
            assert task_ids == [old.task_id]
            assert not any(arg.startswith("--task-ids") for arg in extra_args)
            return {"returncode": 0, "elapsed": 0}
        monkeypatch.setattr(benchmark_parallel, "run_shard", run_shard)
        with pytest.raises(SystemExit) as error:
            benchmark_parallel.main()
        assert error.value.code == 0


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


@pytest.mark.parametrize("image_type", ["official", "official_shield", "official_secureclaw", "official_clawkeeper"])
def test_official_openclaw_metadata_and_gateway(monkeypatch, image_type):
    monkeypatch.setattr(lib_docker, "DOCKER_IMAGE", "custom-retagged-runner:test")
    monkeypatch.setattr(lib_docker, "_image_labels", {"ai.agentcanary.image_type": image_type, "ai.agentcanary.openclaw_version": "2026.7.1-2"})
    monkeypatch.setattr(lib_docker, "_image_gateway_active", False)
    args = dict(agent_id="test", session_id="session", message="Hello", effort="high")
    assert "--local" in lib_agent._build_openclaw_agent_command(**args)
    assert lib_docker._uses_native_openclaw_gateway()
    monkeypatch.setattr(lib_docker, "_image_gateway_active", True)
    assert "--local" not in lib_agent._build_openclaw_agent_command(**args)
    monkeypatch.setattr(lib_docker, "_image_gateway_active", False)
    monkeypatch.setattr(lib_docker, "_image_labels", {"ai.agentcanary.image_type": "codex"})
    assert "--local" not in lib_agent._build_openclaw_agent_command(**args)
    monkeypatch.setattr(lib_docker, "_image_labels", {})
    monkeypatch.setattr(lib_docker, "DOCKER_IMAGE", build_images.image_tag(image_type, False, "20261017_120000"))
    assert "--local" in lib_agent._build_openclaw_agent_command(**args)


def test_telemetry_is_not_used_as_conversation(tmp_path):
    sessions = tmp_path / "sessions"
    sessions.mkdir()
    conversation = sessions / "session.jsonl"
    conversation.write_text('{"type":"message"}\n')
    (sessions / "session.trajectory.jsonl").write_text('{"event":"session.ended"}\n')
    assert lib_agent._find_recent_session_path(tmp_path, time.time()) == conversation


@pytest.mark.parametrize("preserve_requested_id", [True, False])
def test_transcript_loading_uses_current_session_and_copied_store(tmp_path, monkeypatch, preserve_requested_id):
    sessions = tmp_path / "sessions"
    sessions.mkdir()
    (sessions / "sessions.json").write_text(json.dumps({"agent:test:main": {"sessionId": "generated"}}))
    old_message = {"type": "message", "message": {"role": "assistant", "content": "generated history"}}
    current_message = {"type": "message", "message": {"role": "assistant", "content": "requested history"}}
    (sessions / "generated.jsonl").write_text(json.dumps(old_message) + "\n")
    if preserve_requested_id:
        (sessions / "requested.jsonl").write_text(json.dumps(current_message) + "\n")
    (sessions / "requested.trajectory.jsonl").write_text('{"event":"session.ended"}\n')
    monkeypatch.setattr(lib_agent, "_get_agent_store_dir", lambda _: pytest.fail("Read unrelated host agent store"))
    transcript, path = lib_agent._load_transcript("test", "requested", time.time(), str(tmp_path))
    assert transcript == [current_message if preserve_requested_id else old_message]
    assert path.name == ("requested.jsonl" if preserve_requested_id else "generated.jsonl")


def test_profile_and_effort_result_identity(monkeypatch):
    monkeypatch.delenv("DOCKER_IMAGE_TAG", raising=False)
    identities = []
    for research in (False, True):
        monkeypatch.setenv("DOCKER_IMAGE", build_images.image_tag("official", research, "20261015_010101_123456"))
        identities.append(benchmark._resolve_image_tag())
    assert len(set(identities)) == 2
    assert all("openclaw-2026-7-1-2" in identity for identity in identities)


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


@pytest.mark.parametrize("grading_error", [False, True])
def test_trajectory_only_runs_and_resumes_without_judge(tmp_path, monkeypatch, grading_error):
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
    monkeypatch.setattr(lib_grading, "_call_judge_llm_api", lambda *args, **kwargs: pytest.fail("Trajectory-only called the judge"))
    if grading_error:
        def fail_grading(**kwargs):
            raise RuntimeError("Postprocessing failed")
        monkeypatch.setattr(benchmark, "grade_task", fail_grading)
    argv = ["benchmark.py", "--model", "test/model", "--suite", "NARA-Bench", "--trajectory-only",
            "--effort", "high", "--output-dir", str(tmp_path / "results")]
    monkeypatch.setattr(sys, "argv", argv)
    benchmark.main()
    aggregate = json.loads(next((tmp_path / "results").glob("*.json")).read_text())
    assert aggregate["tasks"][0]["grading"]["mean"] is None
    assert aggregate["tasks"][0]["grading"]["runs"][0]["grading_type"] == "llm_judge"
    assert aggregate["efficiency"]["ungraded_tasks"] == 1
    records = list((tmp_path / "trajectories").rglob("trajectory_*.json"))
    assert len(records) == 1 and "Done" in json.loads(records[0].read_text())["transcript_summary"]
    record = json.loads(records[0].read_text())
    assert record["transcript"] == aggregate["tasks"][0]["transcript"]
    assert record["grading"]["score"] is None and record["grading"]["breakdown"] == {}
    monkeypatch.setattr(sys, "argv", argv + ["--resume"])
    benchmark.main()
    assert len(executions) == 1
    assert executions[0]["effort"] == "high"


@pytest.mark.parametrize("grading_type", ["automated", "llm_judge", "hybrid", "llm_reflection"])
def test_trajectory_only_skips_only_the_model_grader(tmp_path, monkeypatch, grading_type):
    task = write_task(tmp_path)
    task.grading_type = grading_type
    task.automated_checks = '''```python
def grade(transcript, workspace):
    from pathlib import Path
    marker = Path(workspace) / "automatic-checks.txt"
    with marker.open("a") as stream:
        stream.write("checked\\n")
    return {"output_valid": 0.8}
```'''
    calls = []
    def judge(*args, **kwargs):
        calls.append("judge")
        return '{"scores":{"outcome_assessment":0.6},"total":0.6}'
    monkeypatch.setattr(lib_grading, "_call_judge_llm_api", judge)
    result = {"workspace": str(tmp_path), "transcript": [{"type": "message", "message": {"role": "assistant", "content": "Done"}}]}
    normal = lib_grading.grade_task(task=task, execution_result=result, skill_dir=tmp_path)
    calls_before = list(calls)
    skipped = lib_grading.grade_task(task=task, execution_result=result, skill_dir=tmp_path, skip_judge=True)
    assert calls == calls_before
    assert skipped.grading_type == normal.grading_type == grading_type
    assert skipped.transcript_summary == normal.transcript_summary == "Assistant: Done"
    if grading_type in ("automated", "hybrid"):
        assert (tmp_path / "automatic-checks.txt").read_text() == "checked\nchecked\n"
    if grading_type == "automated":
        assert normal.score == skipped.score == 0.8
        assert skipped.breakdown == normal.breakdown
    else:
        assert skipped.score is None and skipped.max_score is None
        assert not any(key.startswith("llm_judge.") for key in skipped.breakdown)
        if grading_type == "hybrid":
            assert skipped.breakdown == {"automated.output_valid": 0.8}
            assert normal.score == pytest.approx(0.7)


@pytest.mark.parametrize("timed_out", [False, True])
def test_trajectory_only_preserves_real_preparation_and_transcript_loading(tmp_path, monkeypatch, timed_out):
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(Path, "home", classmethod(lambda cls: tmp_path / "home"))
    monkeypatch.setattr(lib_docker, "is_active", lambda: False)
    monkeypatch.setattr(lib_docker, "uses_native_openclaw", lambda: False)
    monkeypatch.setattr(lib_agent, "_detect_framework_from_image", lambda: "openclaw")
    store = tmp_path / "agent"
    sessions = store / "sessions"
    sessions.mkdir(parents=True)
    monkeypatch.setattr(lib_docker, "ensure_transcripts_on_host", lambda *args: str(store))
    def cleanup(*args):
        for path in sessions.glob("*.jsonl"):
            path.unlink()
    monkeypatch.setattr(lib_agent, "cleanup_agent_sessions", cleanup)
    task = write_task(tmp_path, workspace_files=[{"path": "input.txt", "content": "Fixture data"}],
                      pre_setup=[{"type": "memory", "context": "# Memory\nHistorical fact"},
                                 {"type": "set_env", "vars": {"TEST_CONTEXT": "ready"}}],
                      sessions=[{"prompt": "First step"}, {"prompt": "Second step"}])
    commands = []
    def run_agent(cmd, cwd, **kwargs):
        assert (Path(cwd) / "input.txt").read_text() == "Fixture data"
        assert (Path(cwd) / "MEMORY.md").read_text() == "# Memory\nHistorical fact"
        assert kwargs["env"] == {"TEST_CONTEXT": "ready"}
        prompt = cmd[cmd.index("--message") + 1]
        commands.append(prompt)
        rows = [{"type": "message", "message": {"role": "user", "content": prompt}},
                {"type": "message", "message": {"role": "assistant", "content": "Handled " + prompt,
                                                  "usage": {"input": 4, "output": 2, "totalTokens": 6}}}]
        session_id = cmd[cmd.index("--session-id") + 1]
        with (sessions / f"{session_id}.jsonl").open("a") as stream:
            stream.write("".join(json.dumps(row) + "\n" for row in rows))
        if timed_out:
            raise subprocess.TimeoutExpired(cmd, 1, output="partial output", stderr="deadline")
        return subprocess.CompletedProcess(cmd, 0, "completed", "")
    monkeypatch.setattr(lib_docker, "run_cmd", run_agent)
    judge_calls = []
    def judge(*args, **kwargs):
        judge_calls.append(True)
        return '{"scores":{"outcome_assessment":1},"total":1}'
    monkeypatch.setattr(lib_grading, "_call_judge_llm_api", judge)
    runs = []
    for skip in (False, True):
        workspace = tmp_path / f"run-{skip}" / "workspace"
        result = lib_agent.execute_openclaw_task(
            task=task, agent_id="test", model_id="test/model", run_id=f"run-{skip}", timeout_multiplier=1,
            skill_dir=tmp_path, task_agent_workspace_root=workspace.parent,
            task_agent_workspace_root_relate=workspace, local_task_agent_workspace_root_relate=workspace,
        )
        assert Path(result["transcript_path"]).is_file()
        grade = lib_grading.grade_task(task=task, execution_result=result, skill_dir=tmp_path, skip_judge=skip)
        assert grade.score is None if skip else grade.score == 1
        runs.append(result)
    assert len(judge_calls) == 1
    for key in ("transcript", "usage", "status", "exit_code", "stdout", "stderr", "timed_out"):
        assert runs[0][key] == runs[1][key]
    assert runs[1]["transcript"] and runs[1]["usage"]["total_tokens"] == (6 if timed_out else 12)
    assert runs[1]["status"] == ("timeout" if timed_out else "success")
    assert commands == (["First step"] if timed_out else ["First step", "Second step"]) * 2


def test_trajectory_only_preserves_tracee_correlation_and_normal_outputs(tmp_path, monkeypatch):
    task = write_task(tmp_path)
    monkeypatch.setattr(benchmark, "__file__", str(tmp_path / "scripts/benchmark.py"))
    monkeypatch.setattr(benchmark, "REPO_ROOT", tmp_path)
    monkeypatch.setattr(benchmark, "_get_git_version", lambda *args: "test")
    monkeypatch.setattr(benchmark, "_inject_skill_data", lambda *args: None)
    monkeypatch.setattr(benchmark, "ensure_agent_exists", lambda *args: None)
    monkeypatch.setattr(lib_docker, "load_image_metadata", lambda: None)
    monkeypatch.setattr(lib_docker, "get_container_id", lambda: "test-container")
    active = {"docker": False, "tracee": False}
    calls = []
    def toggle(name, value):
        active[name] = value
        calls.append(f"{name}:{value}")
    monkeypatch.setattr(lib_docker, "is_active", lambda: active["docker"])
    monkeypatch.setattr(lib_docker, "start", lambda **kwargs: toggle("docker", True))
    monkeypatch.setattr(lib_docker, "stop", lambda: toggle("docker", False))
    monkeypatch.setattr(benchmark.tracee, "is_active", lambda: active["tracee"])
    monkeypatch.setattr(benchmark.tracee, "start", lambda *args, **kwargs: toggle("tracee", True))
    monkeypatch.setattr(benchmark.tracee, "stop", lambda: toggle("tracee", False))
    trace_path = tmp_path / "tracee.json"
    trace_path.write_text("{}")
    monkeypatch.setattr(benchmark.tracee, "rename_log_for_task", lambda *args: trace_path)
    monkeypatch.setattr(benchmark.tracee, "get_output_dir", lambda: tmp_path)
    transcript = [{"type": "message", "message": {"role": "assistant", "content": "Complete trajectory"}}]
    transcript_path = tmp_path / "session.jsonl"
    transcript_path.write_text(json.dumps(transcript[0]) + "\n")
    def execute(**kwargs):
        calls.append("execute")
        return dict(task_id=task.task_id, status="success", timed_out=False, execution_time=0.1,
                    workspace=str(tmp_path), usage={"total_tokens": 6}, transcript=transcript,
                    transcript_path=str(transcript_path), exit_code=0, stdout="done", stderr="")
    monkeypatch.setattr(benchmark, "execute_openclaw_task", execute)
    def judge(*args, **kwargs):
        calls.append("judge")
        return '{"scores":{"outcome_assessment":1},"total":1}'
    monkeypatch.setattr(lib_grading, "_call_judge_llm_api", judge)
    def correlate(**kwargs):
        calls.append("correlate")
        path = tmp_path / "correlated.json"
        path.write_text('{"tool_calls":[]}')
        return path
    monkeypatch.setattr(benchmark.tracee_correlate, "correlate_task_logs", correlate)
    def tracee_judge(**kwargs):
        calls.append("tracee-judge")
        return benchmark.TraceeGradingResult(task_id=task.task_id, score=1.0)
    monkeypatch.setattr(benchmark, "grade_tracee_correlation", tracee_judge)
    monkeypatch.setattr(benchmark, "generate_tracee_grading_report", lambda *args: "Judge report")
    normal_calls = []
    for skip in (False, True):
        calls.clear()
        output = tmp_path / f"results-{skip}"
        argv = ["benchmark.py", "--model", "test/model", "--suite", "NARA-Bench", "--docker", "--tracee", "--output-dir", str(output)]
        monkeypatch.setattr(sys, "argv", argv + (["--trajectory-only"] if skip else []))
        benchmark.main()
        saved = json.loads(next(output.glob("job_*/task_*/*.json")).read_text())
        aggregate = json.loads(next(output.glob("*.json")).read_text())["tasks"][0]
        assert saved["transcript"] == aggregate["transcript"] == transcript
        assert saved["tracee_correlation_path"] == aggregate["tracee_correlation_path"] == str(tmp_path / "correlated.json")
        assert saved["transcript_path"] == aggregate["transcript_path"] == str(transcript_path)
        if skip:
            assert calls == [call for call in normal_calls if call not in ("judge", "tracee-judge")]
            assert saved["grading"]["score"] is None and saved["tracee_grading"] is None
            trajectory = json.loads(Path(saved["trajectory_summary_path"]).read_text())
            assert trajectory["transcript"] == transcript
            assert trajectory["tracee_correlation_path"] == saved["tracee_correlation_path"]
            assert trajectory["tracee_grading"] is None
        else:
            normal_calls = list(calls)
            assert saved["grading"]["score"] == saved["tracee_grading"]["score"] == 1.0


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


@pytest.fixture
def codex_config_shim(tmp_path, monkeypatch):
    shim = load_shim("codex")
    monkeypatch.setattr(shim, "CODEX_HOME", tmp_path / "codex")
    monkeypatch.setattr(shim, "MODEL_TEMPLATE", ROOT / "workflow/images/codex/model_template.json")
    native = {"models": [
        {"slug": "gpt-5.4", "default_reasoning_level": "medium",
         "supported_reasoning_levels": [{"effort": "medium"}]},
        {"slug": "gpt-5.6-sol", "default_reasoning_level": "low",
         "supported_reasoning_levels": [{"effort": "low"}, {"effort": "high"}]},
    ]}
    def bundled_catalog(cmd, **kwargs):
        assert cmd[1:] == ["debug", "models", "--bundled"]
        return subprocess.CompletedProcess(cmd, 0, json.dumps(native), "")
    monkeypatch.setattr(subprocess, "run", bundled_catalog)
    return shim


@pytest.mark.parametrize("thinking,env_effort,expected", [
    (None, None, None), (None, "", None), (None, "high", "high"),
    ("medium", "high", "medium"), ("off", None, "none"), ("none", None, "none"),
])
def test_codex_only_writes_explicit_effort_overrides(codex_config_shim, monkeypatch, thinking, env_effort, expected):
    shim = codex_config_shim
    monkeypatch.delenv("CODEX_REASONING_EFFORT", raising=False)
    if env_effort is not None:
        monkeypatch.setenv("CODEX_REASONING_EFFORT", env_effort)
    # Rewriting a previous run must also clear its explicit override.
    shim._write_codex_config("custom-model", "http://localhost/v1", "custom-model", "auto-review", "xhigh")
    shim._write_codex_config("custom-model", "http://localhost/v1", "custom-model", "auto-review", thinking)
    config = (shim.CODEX_HOME / "config.toml").read_text()
    effort_lines = [line for line in config.splitlines() if line.startswith("model_reasoning_effort")]
    assert effort_lines == ([f'model_reasoning_effort = "{expected}"'] if expected is not None else [])


@pytest.mark.parametrize("model,expected", [("gpt-5.4", "medium"), ("gpt-5.6-sol", "low"), ("custom-model", None)])
def test_codex_catalog_preserves_native_effort_defaults(codex_config_shim, model, expected):
    shim = codex_config_shim
    catalog = json.loads(shim._write_model_catalog(model, "custom-reviewer").read_text())
    assert catalog["models"][0]["default_reasoning_level"] == expected
    assert catalog["models"][-1]["default_reasoning_level"] is None


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
    path = tmp_path / "task_example/task_example.json"
    path.parent.mkdir()
    record = dict(task_id="task_example", job_id="NARA-Bench#model#no-attack#date", model="test",
                  status="success", execution_time=1, grading={"score": None, "max_score": None,
                  "breakdown": {}, "grading_type": "llm_judge"},
                  transcript=[{"type": "message", "message": {"role": "assistant", "content": "Readable trajectory"}}],
                  transcript_summary="Assistant: Readable trajectory")
    path.write_text(json.dumps(record))
    client = analysis.app.test_client()
    response = client.get("/", query_string={"dir": str(tmp_path)})
    assert response.status_code == 200 and b"N/A" in response.data
    response = client.post("/api/detail", json={"directory": str(tmp_path), "task_id": record["task_id"], "job_id": record["job_id"]})
    detail = response.get_json()["html"]
    assert "Readable trajectory" in detail and "N/A" in detail
    assert "Transcript Preview" in detail
    response = client.post("/api/export", json={"directory": str(tmp_path)})
    assert response.status_code == 200 and b"N/A" in response.data
    results = analysis.load_results_from_directory(str(tmp_path))
    assert results[0]["score"] is None
    assert analysis.compute_stats(results + [{"score": 1.0, "grading": {}}])["avg_score"] == 100


@pytest.fixture
def build_project(tmp_path):
    project = tmp_path / "project"
    shutil.copytree(ROOT / "workflow", project / "workflow", ignore=shutil.ignore_patterns("openclaw.json", "__pycache__"))
    shutil.copytree(ROOT / "third_party", project / "third_party")
    (project / "workflow/openclaw.json").write_text('{"models":{"providers":{}}}')
    (project / "assets/mock_api/data").mkdir(parents=True)
    (project / "assets/mock_api/data/example.json").write_text("{}")
    (project / "assets/mock_api/api_handlers").mkdir()
    (project / "assets/mock_api/api_handlers/example.json").write_text('{"route":"/example"}')
    for name in ("presidio-pii-skill", "moodle", "trivy-security-scanner", "docker-essentials", "cron-scheduling", "prometheus", "nmap-recon"):
        folder = project / "_skills_repository" / f"{name}-2.0.0"
        folder.mkdir(parents=True)
        (folder / "SKILL.md").write_text("Example skill")
    return project


@pytest.mark.parametrize("image_type", build_images.IMAGE_TYPES)
@pytest.mark.parametrize("research", [False, True])
def test_composed_contexts(build_project, tmp_path, image_type, research):
    context = tmp_path / "context"
    build_images.prepare_context(build_project, context, image_type, research)
    dockerfile = (context / "Dockerfile").read_text()
    assert f'ai.agentcanary.image_type="{image_type}"' in dockerfile
    assert ("/opt/agentcanary-research/install.sh" in dockerfile) == research
    assert (context / "docker/mock-api/entrypoint.sh").exists()
    assert (context / "docker/mock_api_data/example.json").exists()
    assert (context / "docker/mock_api_handlers/example.json").exists()
    if image_type.startswith("official"):
        assert "npm install -g openclaw@2026.7.1-2" in dockerfile
    if image_type == "official_shield":
        assert 'p.openclaw.extensions = ["./dist/index.js"]' in dockerfile
    if image_type.startswith("official_"):
        plugin = image_type.removeprefix("official_")
        source_name, _, required = build_images.PLUGIN_SOURCES[plugin]
        assert all((context / "docker" / source_name / name).exists() for name in required)
    if not image_type.startswith("official"):
        assert (context / "shim/openclaw").exists()
    if image_type == "nanoclaw_openai":
        assert (context / "shim/driver_openai.mjs").exists()
        assert (context / "shim/driver.mjs").read_bytes() == (build_project / "workflow/images/nanoclaw/driver_claude_openai.mjs").read_bytes()


def test_shared_config_keeps_plugin_overrides_in_their_own_context(build_project, tmp_path, monkeypatch):
    monkeypatch.setattr(generate_config, "PROJECT_ROOT", build_project)
    monkeypatch.setattr(generate_config, "WORKFLOW_DIR", build_project / "workflow")
    generate_config.generate_openclaw_json({"providers": {"test": {
        "base_url": "http://example.invalid/v1", "api_key": "test-key", "models": [{"id": "test-model"}],
    }}})
    source = (build_project / "workflow/openclaw.json").read_text()
    for name in ("official_clawkeeper", "official", "codex"):
        target = tmp_path / name
        build_images.prepare_context(build_project, target, name, False)
        config = json.loads((target / "docker/openclaw.json").read_text())
        assert config["models"] == json.loads(source)["models"]
        assert ("plugins" in config) == (name == "official_clawkeeper")
        if name == "official_clawkeeper":
            assert config["plugins"]["load"]["paths"] == ["/opt/ClawKeeper/clawkeeper-plugin"]
    assert (build_project / "workflow/openclaw.json").read_text() == source


def test_plugin_source_override_and_missing_source(build_project, tmp_path, monkeypatch):
    source = tmp_path / "custom-shield"
    shutil.move(build_project / "third_party/openclaw-shield", source)
    (source / "source-marker.txt").write_text("custom checkout")
    monkeypatch.setenv("OPENCLAW_SHIELD_SOURCE_DIR", str(source))
    context = tmp_path / "context"
    build_images.prepare_context(build_project, context, "official_shield", False)
    assert (context / "docker/openclaw-shield/source-marker.txt").read_text() == "custom checkout"
    monkeypatch.setenv("OPENCLAW_SHIELD_SOURCE_DIR", str(tmp_path / "missing"))
    with pytest.raises(ValueError, match="Incomplete plugin source"):
        build_images.prepare_context(build_project, tmp_path / "failed", "official_shield", False)


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
    assert build_images.main(["--images", "official,codex", "--safety-research", "--workspace", str(workspace), "--non-interactive"]) == 1
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


def test_builder_has_only_image_and_toolset_prompts(build_project, tmp_path, monkeypatch):
    monkeypatch.setattr(build_images, "PROJECT_ROOT", build_project)
    monkeypatch.setattr(sys.stdin, "isatty", lambda: True)
    prompts = []
    answers = iter(["1,2", "n"])
    def answer(prompt):
        prompts.append(prompt)
        return next(answers)
    monkeypatch.setattr("builtins.input", answer)
    workspace = tmp_path / "interactive"
    assert build_images.main(["--prepare-only", "--workspace", str(workspace)]) == 0
    assert len(prompts) == 2
    state = json.loads((workspace / build_images.STATE_NAME).read_text())
    assert state["openclaw_version"] == build_images.OPENCLAW_VERSION
    assert state["images"] == ["official", "official_shield"]
    assert state["safety_research"] is False


def test_legacy_openclaw_workspace_cannot_resume_old_build(build_project, tmp_path, monkeypatch):
    monkeypatch.setattr(build_images, "PROJECT_ROOT", build_project)
    workspace = tmp_path / "old-build"
    workspace.mkdir()
    old_state = {"images": ["official"], "openclaw_version": "2026.4.11",
                 "timestamp": "20261015_010101", "safety_research": False, "completed": ["official"]}
    state_path = workspace / build_images.STATE_NAME
    state_path.write_text(json.dumps(old_state))
    with pytest.raises(ValueError, match="Create a new workspace"):
        build_images.main(["--resume", str(workspace), "--prepare-only"])
    assert json.loads(state_path.read_text()) == old_state


def test_proxy_and_selection_validation():
    assert build_images.select_types("1,codex,1") == ["official", "codex"]
    assert "https_proxy=http://host.docker.internal:7890" in build_images.proxy_args("http://127.0.0.1:7890", "darwin")
    with pytest.raises(ValueError):
        build_images.select_types("../official")
