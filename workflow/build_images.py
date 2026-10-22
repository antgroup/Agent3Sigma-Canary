#!/usr/bin/env python3
"""Build in two stages: choose agent images, then optionally add safety research tools."""

from __future__ import annotations

import argparse
from datetime import datetime
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from urllib.parse import urlsplit, urlunsplit

PROJECT_ROOT = Path(__file__).resolve().parent.parent
IMAGE_TYPES = (
    "official", "official_shield", "official_secureclaw", "official_clawkeeper",
    "hermes", "nanoclaw", "claude_code", "codex", "nanoclaw_openai",
)
IMAGE_DESCRIPTIONS = {
    "official": "OpenClaw",
    "official_shield": "OpenClaw + Shield",
    "official_secureclaw": "OpenClaw + SecureClaw",
    "official_clawkeeper": "OpenClaw + ClawKeeper",
    "hermes": "Hermes",
    "nanoclaw": "NanoClaw",
    "claude_code": "Claude Code",
    "codex": "Codex",
    "nanoclaw_openai": "NanoClaw + OpenAI via OpenCode",
}
PLUGIN_SOURCES = {
    "shield": ("openclaw-shield", "OPENCLAW_SHIELD_SOURCE_DIR",
               ("package.json", "openclaw.plugin.json", "src")),
    "secureclaw": ("secureclaw", "SECURECLAW_SOURCE_DIR",
                   ("secureclaw/package.json", "secureclaw/openclaw.plugin.json", "secureclaw/src")),
    "clawkeeper": ("ClawKeeper", "CLAWKEEPER_SOURCE_DIR",
                   ("clawkeeper-plugin/package.json", "clawkeeper-plugin/openclaw.plugin.json",
                    "clawkeeper-plugin/install.sh")),
}
OPENCLAW_VERSION = "2026.7.1-2"
STATE_NAME = ".build_state.json"


def select_types(value: str) -> list[str]:
    if value.strip().lower() in ("all", "a"):
        return list(IMAGE_TYPES)
    selected = []
    for item in value.split(","):
        item = item.strip()
        if item.isdigit() and 1 <= int(item) <= len(IMAGE_TYPES):
            item = IMAGE_TYPES[int(item) - 1]
        if item not in IMAGE_TYPES:
            raise ValueError(f"Unknown image type: {item!r}; choose from {', '.join(IMAGE_TYPES)}")
        if item not in selected:
            selected.append(item)
    return selected


def image_tag(image_type: str, research: bool, timestamp: str) -> str:
    suffix = ""
    if image_type.startswith("official"):
        suffix += f"-openclaw-{OPENCLAW_VERSION}"
    if research:
        suffix += "-safety_research"
    return f"openclaw-{image_type}{suffix}-v{timestamp}"


def prepare_context(project: Path, context: Path, image_type: str, research: bool) -> None:
    """Stage locally available inputs; network access happens only during Docker build."""
    if image_type not in IMAGE_TYPES:
        raise ValueError(f"Unknown image type: {image_type!r}")
    workflow = project / "workflow"
    family = "openclaw" if image_type.startswith("official") else image_type.removesuffix("_openai")
    image_dir = workflow / "images" / family
    plugin = image_type.removeprefix("official_") if image_type.startswith("official_") else None
    config_path = workflow / "openclaw.json"
    if not config_path.is_file():
        raise ValueError(f"Missing {config_path}; run bash setup.sh first")
    config = json.loads(config_path.read_text())
    if plugin:
        overrides = image_dir / f"{plugin}.overrides.json"
        if overrides.exists():
            config.update(json.loads(overrides.read_text()))
    context.mkdir(parents=True, exist_ok=True)
    docker = context / "docker"
    docker.mkdir(exist_ok=True)
    (docker / "openclaw.json").write_text(json.dumps(config, indent=2, ensure_ascii=False) + "\n")
    shutil.copytree(workflow / "mock-api", docker / "mock-api", dirs_exist_ok=True,
                    ignore=shutil.ignore_patterns("__pycache__", "*.pyc", ".pid"))
    for folder, context_name in (("data", "mock_api_data"), ("api_handlers", "mock_api_handlers")):
        source = project / "assets" / "mock_api" / folder
        target = docker / context_name
        target.mkdir(exist_ok=True)
        if source.is_dir():
            if folder == "data":
                shutil.copytree(source, target, dirs_exist_ok=True)
            else:
                for handler in source.glob("*.json"):
                    shutil.copy2(handler, target / handler.name)
    if family != "openclaw":
        shim = context / "shim"
        shim.mkdir(exist_ok=True)
        legacy_openai = image_type == "nanoclaw_openai"
        shutil.copy2(image_dir / ("openclaw_openai" if legacy_openai else "openclaw"), shim / "openclaw")
        (shim / "openclaw").chmod((shim / "openclaw").stat().st_mode | 0o111)
        if family in ("codex", "claude_code"):
            shutil.copy2(workflow / "agentcanary_runtime.py", shim / "agentcanary_runtime.py")
        if family == "nanoclaw":
            shutil.copy2(image_dir / ("driver_claude_openai.mjs" if legacy_openai else "driver.mjs"), shim / "driver.mjs")
            if legacy_openai:
                shutil.copy2(image_dir / "driver_openai.mjs", shim / "driver_openai.mjs")
        if family == "codex":
            shutil.copy2(image_dir / "model_template.json", docker / "model_template.json")
    dockerfile = context / "Dockerfile"
    template = image_dir / ("Dockerfile.openai" if image_type == "nanoclaw_openai" else "Dockerfile")
    content = template.read_text()
    if family == "openclaw":
        content = content.replace("@OPENCLAW_VERSION@", OPENCLAW_VERSION)
        fragment = ""
        if plugin:
            source_name, env_name, required = PLUGIN_SOURCES[plugin]
            source = Path(os.environ.get(env_name) or project / "third_party" / source_name)
            if any(not (source / name).exists() for name in required):
                raise ValueError(f"Incomplete plugin source: {source}; set {env_name} to a complete local checkout")
            shutil.copytree(source, docker / source_name, dirs_exist_ok=True,
                            ignore=shutil.ignore_patterns(".git", "__pycache__", "node_modules"))
            fragment = (image_dir / f"Dockerfile.{plugin}").read_text()
        content = content.replace("# OPTIONAL_PLUGIN_LAYER", fragment)
    if research:
        feature_dir = workflow / "tools"
        shutil.copytree(feature_dir, context / "research", dirs_exist_ok=True)
        local_skills = (
            "presidio-pii-skill", "moodle", "trivy-security-scanner", "docker-essentials",
            "cron-scheduling", "prometheus", "nmap-recon",
        )
        for name in local_skills:
            source = project / "_skills_repository" / f"{name}-2.0.0"
            shutil.copytree(source, context / "research" / "skills" / name, dirs_exist_ok=True)
        content += (
            "\n# Optional shared safety research tools and skills.\n"
            "USER root\n"
            "COPY research/ /opt/agentcanary-research/\n"
            "RUN bash /opt/agentcanary-research/install.sh\n"
            f"RUN /usr/bin/python3 /opt/agentcanary-research/install_skills.py {image_type}\n"
            "WORKDIR /workspace\n"
        )
    content += (
        f'\nLABEL ai.agentcanary.image_type="{image_type}" '
        f'ai.agentcanary.safety_research="{str(research).lower()}"\n'
    )
    if image_type.startswith("official"):
        content += f'LABEL ai.agentcanary.openclaw_version="{OPENCLAW_VERSION}"\n'
    dockerfile.write_text(content)


def proxy_args(proxy: str | None, platform: str = sys.platform) -> list[str]:
    if not proxy:
        return []
    url = urlsplit(proxy)
    if url.scheme not in ("http", "https") or not url.hostname:
        raise ValueError("--proxy requires an HTTP(S) URL")
    extra = []
    if platform.startswith("linux"):
        extra = ["--network", "host"]
    elif url.hostname in ("localhost", "127.0.0.1", "::1"):
        netloc = "host.docker.internal" + (f":{url.port}" if url.port else "")
        proxy = urlunsplit((url.scheme, netloc, url.path, url.query, url.fragment))
    return extra + ["--build-arg", f"http_proxy={proxy}", "--build-arg", f"https_proxy={proxy}"]


def save_state(path: Path, state: dict) -> None:
    temp = path.with_suffix(".tmp")
    temp.write_text(json.dumps(state, indent=2) + "\n")
    temp.replace(path)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--images", help="Comma-separated image types or all (interactive menu if omitted)")
    parser.add_argument("--safety-research", action=argparse.BooleanOptionalAction, default=None,
                        help="Add document, PII, finance, operations and WordPress research tools")
    parser.add_argument("--proxy", help="HTTP(S) proxy used during Docker build")
    parser.add_argument("--prepare-only", action="store_true", help="Prepare build contexts without Docker or downloads")
    parser.add_argument("--non-interactive", action="store_true", help="Use defaults instead of prompting")
    parser.add_argument("--workspace", type=Path, help="New workspace path (must be empty)")
    parser.add_argument("--resume", type=Path, help="Resume a workspace using its saved options")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    if args.resume:
        if any(value is not None for value in (args.images, args.safety_research, args.proxy, args.workspace)):
            raise ValueError("--resume uses saved build options; create a new workspace to change them")
        workspace = args.resume.resolve()
        state = json.loads((workspace / STATE_NAME).read_text())
        # Validate values before they are used in paths or generated Dockerfiles.
        state["images"] = select_types(",".join(state["images"]))
        if (any(name.startswith("official") for name in state["images"])
                and state.get("openclaw_version") != OPENCLAW_VERSION):
            raise ValueError(
                f"Saved workspace uses OpenClaw {state.get('openclaw_version')}; "
                f"only {OPENCLAW_VERSION} is supported. Create a new workspace to rebuild."
            )
        state["openclaw_version"] = OPENCLAW_VERSION
        if not isinstance(state["safety_research"], bool):
            raise ValueError("Invalid safety_research value in saved build state")
        if not re.fullmatch(r"[0-9_]+", state["timestamp"]):
            raise ValueError("Invalid timestamp in saved build state")
    else:
        interactive = sys.stdin.isatty() and not args.non_interactive
        if interactive:
            print("\n[1/2] Choose agent images")
        types = args.images
        if types is None and interactive:
            for index, name in enumerate(IMAGE_TYPES, 1):
                print(f"  [{index}] {name} ({IMAGE_DESCRIPTIONS[name]})")
            types = input("Select images (comma-separated numbers/names, A = all) [1]: ").strip() or "official"
        images = select_types(types or "official")
        if interactive:
            print(f"Selected images: {', '.join(images)}")
        if interactive:
            print("\n[2/2] Choose optional tools")
            print("The safety_research toolset adds document/OCR, PII, finance, operations, "
                  "and WordPress tools with related skills.")
            print("This choice applies to all selected images. Default: keep the base toolset.")
        research = args.safety_research
        if research is None and interactive:
            while True:
                answer = input("Add the safety_research toolset? [y/N]: ").strip().lower()
                if answer in ("", "n", "no", "y", "yes"):
                    research = answer in ("y", "yes")
                    break
                print("Please enter y (add tools) or n (keep the base toolset).")
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
        workspace = (args.workspace or PROJECT_ROOT / ".workspaces" / f"AgentCanary_{timestamp}").resolve()
        if workspace.exists() and any(workspace.iterdir()):
            raise ValueError(f"Workspace is not empty: {workspace}; use --resume or a new path")
        state = {
            "schema_version": 1, "timestamp": timestamp, "images": images,
            "openclaw_version": OPENCLAW_VERSION,
            "safety_research": bool(research), "proxy": args.proxy,
            "completed": [],
        }

    print(f"\nImages: {', '.join(state['images'])}")
    if any(name.startswith("official") for name in state["images"]):
        print(f"OpenClaw version: {state['openclaw_version']}")
    print(f"safety_research toolset: {'enabled' if state['safety_research'] else 'disabled'}", flush=True)
    build_proxy_args = proxy_args(state.get("proxy"))
    if not args.prepare_only and shutil.which("docker") is None:
        raise ValueError("Docker is required; use --prepare-only to stage contexts without it")
    workspace.mkdir(parents=True, exist_ok=True)
    save_state(workspace / STATE_NAME, state)
    failed = []
    built_tags = []
    for image_type in state["images"]:
        research = state["safety_research"]
        tag = image_tag(image_type, research, state["timestamp"])
        context = workspace / f"build_{image_type}"
        if not args.prepare_only and image_type in state["completed"]:
            inspected = subprocess.run(["docker", "image", "inspect", tag], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if inspected.returncode == 0:
                print(f"Already built: {tag}", flush=True)
                built_tags.append(tag)
                continue
        try:
            prepare_context(PROJECT_ROOT, context, image_type, research)
            print(f"Context: {context}", flush=True)
            if args.prepare_only:
                print(f"Planned image (not built): {tag}", flush=True)
                continue
            subprocess.run(["docker", "build", "-f", str(context / "Dockerfile"), "-t", tag,
                            *build_proxy_args, str(context)], check=True)
            if image_type not in state["completed"]:
                state["completed"].append(image_type)
            save_state(workspace / STATE_NAME, state)
            built_tags.append(tag)
            print(f"Built image: {tag}", flush=True)
        except (ValueError, OSError, subprocess.CalledProcessError) as exc:
            print(f"Failed to prepare/build {image_type}: {exc}", file=sys.stderr)
            failed.append(image_type)
    print(f"Workspace: {workspace}\nResume: bash workflow/workflow_step_1_image_builder.sh --resume {workspace}")
    if failed:
        print(f"Failed images: {', '.join(failed)}", file=sys.stderr)
    if built_tags:
        print("\nBuilt images:", flush=True)
        for tag in built_tags:
            print(f"  {tag}", flush=True)
    return 1 if failed else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        sys.exit(2)
