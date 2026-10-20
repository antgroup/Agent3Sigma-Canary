"""Network policy regressions at the Docker startup/restart boundary."""

import importlib.util
from pathlib import Path
import subprocess

import pytest


@pytest.mark.parametrize("enabled", [False, True])
@pytest.mark.parametrize("image,labels", [
    ("openclaw-official:test", {}),
    ("openclaw-official-safety_research:test", {}),
    ("openclaw-codex-safety_research:test",
     {"ai.agentcanary.image_type": "codex", "ai.agentcanary.safety_research": "true"}),
    ("custom-retagged-runner:test", {"ai.agentcanary.safety_research": "true"}),
])
def test_netlock_applies_on_start_and_restart(monkeypatch, enabled, image, labels):
    # Load after setting the obsolete override: even an old deployment's
    # explicit exemption must not defeat --netlock.
    monkeypatch.setenv("DOCKER_OPEN_EGRESS_IMAGE_PATTERNS", f"safety_research,{image}")
    monkeypatch.setenv("DOCKER_IMAGE", image)
    spec = importlib.util.spec_from_file_location(
        "docker_netlock_runtime", Path(__file__).with_name("lib_docker.py"),
    )
    docker = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(docker)
    events = []
    starts = 0

    def invoke(cmd, **kwargs):
        nonlocal starts
        if cmd[:3] == ["docker", "image", "inspect"]:
            import json
            return subprocess.CompletedProcess(cmd, 0, json.dumps(labels), "")
        if cmd[:2] == ["docker", "run"]:
            starts += 1
            container = f"container-{starts}"
            events.append(("start", container))
            return subprocess.CompletedProcess(cmd, 0, container, "")
        if cmd[:2] == ["docker", "exec"]:
            container = cmd[cmd.index("bash") - 1]
            assert events[-1] == ("ready", container)
            assert cmd[-1] == docker._EGRESS_LOCKDOWN_SCRIPT
            assert f"EXTRA_ALLOW_HOSTS={docker.DOCKER_EGRESS_ALLOW_HOSTS}" in cmd
            assert f"ALLOW_CIDRS={docker.DOCKER_EGRESS_ALLOW_CIDRS}" in cmd
            events.append(("lock", container))
            return subprocess.CompletedProcess(cmd, 0, "", "")
        assert cmd[:3] == ["docker", "rm", "-f"]
        events.append(("remove", cmd[-1]))
        return subprocess.CompletedProcess(cmd, 0, "", "")

    monkeypatch.setattr(subprocess, "run", invoke)
    monkeypatch.setattr(docker, "_wait_for_mock_api_ready",
                        lambda container: events.append(("ready", container)))
    docker.configure_egress_lockdown(enabled)
    first = docker.start()
    second = docker.restart()
    assert first != second
    expected = [("start", first), ("ready", first)]
    if enabled:
        expected.append(("lock", first))
    expected += [("remove", first), ("start", second), ("ready", second)]
    if enabled:
        expected.append(("lock", second))
    assert events == expected
    docker.stop()
