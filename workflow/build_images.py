#!/usr/bin/env python3
"""Compose agent images with optional research tools and a pinned OpenClaw version."""

from __future__ import annotations

import argparse
from datetime import datetime
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
from urllib.parse import urlsplit, urlunsplit

PROJECT_ROOT = Path(__file__).resolve().parent.parent
IMAGE_TYPES = (
    "official", "official_shield", "official_secureclaw", "official_clawkeeper",
    "hermes", "nanoclaw", "claude_code", "codex",
)
DEFAULT_OPENCLAW_VERSION = "2026.4.11"
NEW_OPENCLAW_VERSION = "2026.7.1-2"
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


def resolve_version(value: str) -> str:
    value = {"default": DEFAULT_OPENCLAW_VERSION, "newest": NEW_OPENCLAW_VERSION}.get(value, value)
    if not re.fullmatch(r"\d+\.\d+\.\d+(?:-[A-Za-z0-9.]+)?", value):
        raise ValueError("--openclaw-version must be an exact version, 'default', or 'newest'")
    return value


def image_tag(image_type: str, version: str, research: bool, timestamp: str) -> str:
    suffix = ""
    if image_type.startswith("official") and version != DEFAULT_OPENCLAW_VERSION:
        suffix += f"-openclaw-{version}"
    if research:
        suffix += "-safety_research"
    return f"openclaw-{image_type}{suffix}-v{timestamp}"


def prepare_context(project: Path, context: Path, image_type: str, version: str, research: bool) -> None:
    """Stage locally available inputs; network access happens only during Docker build."""
    image_dir = project / "workflow" / "images" / image_type
    context.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["bash", "-e", str(image_dir / "prepare.sh"), str(context), "", str(project)],
        cwd=project, check=True,
    )
    dockerfile = context / "Dockerfile"
    content = dockerfile.read_text()
    if image_type.startswith("official"):
        content = content.replace(
            f"ARG OPENCLAW_VERSION={DEFAULT_OPENCLAW_VERSION}", f"ARG OPENCLAW_VERSION={version}"
        )
    if research:
        feature_dir = project / "workflow" / "features" / "safety_research"
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
        content += 'LABEL ai.agentcanary.openclaw_version="${OPENCLAW_VERSION}"\n'
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
    parser.add_argument("--openclaw-version", help=f"Exact version, default ({DEFAULT_OPENCLAW_VERSION}), or newest ({NEW_OPENCLAW_VERSION})")
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
        if any(value is not None for value in (args.images, args.openclaw_version, args.safety_research, args.proxy, args.workspace)):
            raise ValueError("--resume uses saved build options; create a new workspace to change them")
        workspace = args.resume.resolve()
        state = json.loads((workspace / STATE_NAME).read_text())
        # Validate values before they are used in paths or generated Dockerfiles.
        state["images"] = select_types(",".join(state["images"]))
        state["openclaw_version"] = resolve_version(state["openclaw_version"])
        if not isinstance(state["safety_research"], bool):
            raise ValueError("Invalid safety_research value in saved build state")
        if not re.fullmatch(r"[0-9_]+", state["timestamp"]):
            raise ValueError("Invalid timestamp in saved build state")
    else:
        interactive = sys.stdin.isatty() and not args.non_interactive
        types = args.images
        if types is None and interactive:
            print("Agent image types:")
            for index, name in enumerate(IMAGE_TYPES, 1):
                print(f"  [{index}] {name}")
            types = input("Select types (comma-separated numbers/names, A = all) [1]: ").strip() or "official"
        images = select_types(types or "official")
        version = args.openclaw_version
        if version is None and interactive and any(name.startswith("official") for name in images):
            version = input(f"OpenClaw version [default={DEFAULT_OPENCLAW_VERSION}; newest={NEW_OPENCLAW_VERSION}]: ").strip()
        research = args.safety_research
        if research is None and interactive:
            research = input("Install safety research tools? [y/N]: ").strip().lower() in ("y", "yes")
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
        workspace = (args.workspace or PROJECT_ROOT / ".workspaces" / f"AgentCanary_{timestamp}").resolve()
        if workspace.exists() and any(workspace.iterdir()):
            raise ValueError(f"Workspace is not empty: {workspace}; use --resume or a new path")
        state = {
            "schema_version": 1, "timestamp": timestamp, "images": images,
            "openclaw_version": resolve_version(version or "default"),
            "safety_research": bool(research), "proxy": args.proxy,
            "completed": [],
        }

    build_proxy_args = proxy_args(state.get("proxy"))
    if not args.prepare_only and shutil.which("docker") is None:
        raise ValueError("Docker is required; use --prepare-only to stage contexts without it")
    workspace.mkdir(parents=True, exist_ok=True)
    save_state(workspace / STATE_NAME, state)
    failed = []
    for image_type in state["images"]:
        version, research = state["openclaw_version"], state["safety_research"]
        tag = image_tag(image_type, version, research, state["timestamp"])
        context = workspace / f"build_{image_type}"
        if not args.prepare_only and image_type in state["completed"]:
            inspected = subprocess.run(["docker", "image", "inspect", tag], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if inspected.returncode == 0:
                print(f"Already built: {tag}", flush=True)
                continue
        try:
            prepare_context(PROJECT_ROOT, context, image_type, version, research)
            print(f"Context: {context}\nImage: {tag}", flush=True)
            if args.prepare_only:
                continue
            subprocess.run(["docker", "build", "-f", str(context / "Dockerfile"), "-t", tag,
                            *build_proxy_args, str(context)], check=True)
            if image_type not in state["completed"]:
                state["completed"].append(image_type)
            save_state(workspace / STATE_NAME, state)
        except (OSError, subprocess.CalledProcessError) as exc:
            print(f"Failed to prepare/build {image_type}: {exc}", file=sys.stderr)
            failed.append(image_type)
    print(f"Workspace: {workspace}\nResume: bash workflow/workflow_step_1_image_builder.sh --resume {workspace}")
    if failed:
        print(f"Failed images: {', '.join(failed)}", file=sys.stderr)
    return 1 if failed else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, OSError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        sys.exit(2)
