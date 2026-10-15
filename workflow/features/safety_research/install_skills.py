#!/usr/bin/env python3
"""Install the optional research profile's local and pinned community skills."""

from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from urllib.parse import urlencode
import zipfile


def unpack_skill(archive: Path, target: Path) -> None:
    target.mkdir(parents=True, exist_ok=True)
    root = target.resolve()
    with zipfile.ZipFile(archive) as bundle:
        for member in bundle.infolist():
            destination = (root / member.filename).resolve()
            if destination != root and root not in destination.parents:
                raise ValueError(f"Unsafe archive member: {member.filename}")
            if member.is_dir():
                continue
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(bundle.read(member))
    if not (root / "SKILL.md").is_file():
        raise ValueError(f"Downloaded skill has no SKILL.md: {target.name}")


def main(framework: str) -> None:
    root = Path("/root/.openclaw/skills")
    shutil.copytree(Path(__file__).parent / "skills", root, dirs_exist_ok=True)
    community_skills = (
        ("", "pandoc", "1.0.2"),
        ("bisbeebucky", "hledger", "1.0.0"),
        ("moep90", "restic-home-backup", "1.0.2"),
        ("whalefell", "tesseract-ocr", "1.0.0"),
    )
    with tempfile.TemporaryDirectory() as temp:
        for owner, slug, version in community_skills:
            query = {"slug": slug, "version": version}
            if owner:
                query["owner"] = owner
            archive = Path(temp) / f"{slug}.zip"
            subprocess.run(["curl", "-fsSL", "--retry", "3", "--max-time", "120",
                            "https://clawhub.ai/api/v1/download?" + urlencode(query),
                            "-o", str(archive)], check=True)
            unpack_skill(archive, root / slug)
    for script in root.rglob("*"):
        if script.is_file() and script.suffix in (".sh", ".py"):
            script.chmod(script.stat().st_mode | 0o111)
    native = {
        "claude_code": "/root/.claude/skills", "nanoclaw": "/root/.claude/skills",
        "codex": "/root/.agents/skills", "hermes": "/root/.hermes/skills",
    }.get(framework)
    if native:
        shutil.copytree(root, native, dirs_exist_ok=True)
    if framework == "hermes":
        Path("/root/.hermes/skills.bundled").write_text(
            "".join(f"{path.name}\n" for path in sorted(Path(native).iterdir()) if path.is_dir())
        )


if __name__ == "__main__":
    main(sys.argv[1])
