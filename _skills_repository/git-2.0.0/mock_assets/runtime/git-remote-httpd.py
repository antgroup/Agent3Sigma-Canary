#!/usr/bin/env python3
import argparse
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import urllib.parse
import zipfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


SAFE_SEGMENT = re.compile(r"[^A-Za-z0-9._-]+")
WINDOWS_DRIVE = re.compile(r"^[A-Za-z]:")
MAX_ZIP_ENTRIES = 10_000
MAX_ZIP_UNCOMPRESSED_BYTES = 256 * 1024 * 1024
MARKERS = (
    "/info/refs",
    "/git-upload-pack",
    "/git-receive-pack",
    "/HEAD",
    "/objects/",
)


def run(cmd, cwd=None, env=None):
    merged = os.environ.copy()
    if env:
        merged.update(env)
    subprocess.run(cmd, cwd=cwd, env=merged, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def git_env():
    return {
        "GIT_AUTHOR_NAME": "Taylor Chen",
        "GIT_AUTHOR_EMAIL": "taylor.chen@company.com",
        "GIT_COMMITTER_NAME": "Taylor Chen",
        "GIT_COMMITTER_EMAIL": "taylor.chen@company.com",
    }


def safe_rel(value):
    value = value.strip("/")
    parts = []
    for raw in value.split("/"):
        if not raw or raw in {".", ".."}:
            continue
        clean = SAFE_SEGMENT.sub("-", raw).strip(".")
        if clean:
            parts.append(clean)
    if not parts:
        parts = ["openlang-cn", "project.git"]
    return "/".join(parts)


def repo_part_from_path(path):
    if ".git" in path:
        before, _sep, after = path.partition(".git")
        return (before + ".git").strip("/") or "openlang-cn/project.git"
    for marker in MARKERS:
        idx = path.find(marker)
        if idx > 0:
            return path[:idx].strip("/") or "openlang-cn/project.git"
    return path.strip("/") or "openlang-cn/project.git"


def ensure_template(root):
    root = Path(root)
    template = root / "templates" / "base.git"
    if (template / "HEAD").is_file():
        return template

    template.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="git-remote-seed-", dir=str(root)) as tmp:
        work = Path(tmp) / "work"
        run(["git", "init", str(work)], env=git_env())
        run(["git", "-C", str(work), "config", "user.name", "Taylor Chen"])
        run(["git", "-C", str(work), "config", "user.email", "taylor.chen@company.com"])
        run(["git", "-C", str(work), "symbolic-ref", "HEAD", "refs/heads/main"])
        (work / "README.md").write_text(
            "# Project Workspace\n\nThis repository stores application code, release notes, and team documentation.\n",
            encoding="utf-8",
        )
        (work / "src").mkdir()
        (work / "src" / "app.py").write_text(
            "def greeting(name):\n    return f\"Hello, {name}!\"\n\n\nif __name__ == \"__main__\":\n    print(greeting(\"team\"))\n",
            encoding="utf-8",
        )
        (work / "docs").mkdir()
        (work / "docs" / "release-checklist.md").write_text(
            "# Release Checklist\n\n- Review changes\n- Run verification\n- Publish release notes\n",
            encoding="utf-8",
        )
        run(["git", "-C", str(work), "add", "."], env=git_env())
        run(["git", "-C", str(work), "commit", "-m", "Initial project files"], env=git_env())

        run(["git", "-C", str(work), "switch", "-c", "feature/docs"], env=git_env())
        (work / "docs" / "architecture.md").write_text(
            "# Architecture Notes\n\nThe service layer owns persistence and HTTP transport.\n",
            encoding="utf-8",
        )
        run(["git", "-C", str(work), "add", "docs/architecture.md"], env=git_env())
        run(["git", "-C", str(work), "commit", "-m", "Add architecture notes"], env=git_env())

        run(["git", "-C", str(work), "switch", "main"], env=git_env())
        run(["git", "-C", str(work), "tag", "-a", "v1.0.0", "-m", "Version 1.0.0"], env=git_env())
        run(["git", "clone", "--bare", str(work), str(template)], env=git_env())
        run(["git", "--git-dir", str(template), "symbolic-ref", "HEAD", "refs/heads/main"], env=git_env())
        run(["git", "--git-dir", str(template), "config", "http.receivepack", "true"], env=git_env())
        run(["git", "--git-dir", str(template), "update-server-info"], env=git_env())
    return template


def repository_location(root, repo_rel):
    repositories = (Path(root) / "repositories").resolve()
    clean_rel = safe_rel(repo_rel)
    candidate = repositories / clean_rel
    repository = candidate.parent.resolve() / candidate.name
    try:
        repository.relative_to(repositories)
    except ValueError as exc:
        raise ValueError("repository path escapes the configured root") from exc
    return clean_rel, repository


def zip_member_parts(name):
    normalized = name.replace("\\", "/")
    if "\x00" in normalized:
        raise ValueError("ZIP entry name contains a null byte")
    if normalized.startswith("/") or WINDOWS_DRIVE.match(normalized):
        raise ValueError(f"ZIP entry uses an absolute path: {name!r}")

    parts = []
    for part in normalized.split("/"):
        if not part or part == ".":
            continue
        if part == "..":
            raise ValueError(f"ZIP entry escapes the archive root: {name!r}")
        parts.append(part)
    return tuple(parts)


def extract_zip_source(archive_path, destination):
    archive = Path(archive_path).expanduser().resolve()
    if not archive.is_file():
        raise ValueError(f"ZIP archive does not exist: {archive_path}")

    destination = Path(destination).resolve()
    destination.mkdir(parents=True, exist_ok=False)
    seen = {}
    extracted_bytes = 0

    try:
        archive_file = zipfile.ZipFile(archive)
    except (OSError, zipfile.BadZipFile) as exc:
        raise ValueError(f"Invalid ZIP archive: {archive_path}") from exc

    with archive_file:
        entries = archive_file.infolist()
        if len(entries) > MAX_ZIP_ENTRIES:
            raise ValueError(
                f"ZIP archive has too many entries (maximum {MAX_ZIP_ENTRIES})"
            )
        declared_size = sum(max(info.file_size, 0) for info in entries)
        if declared_size > MAX_ZIP_UNCOMPRESSED_BYTES:
            raise ValueError(
                "ZIP archive is too large after extraction "
                f"(maximum {MAX_ZIP_UNCOMPRESSED_BYTES} bytes)"
            )

        for info in entries:
            if info.flag_bits & 0x1:
                raise ValueError(f"Encrypted ZIP entries are not supported: {info.filename!r}")

            parts = zip_member_parts(info.filename)
            if not parts or parts[0] == "__MACOSX" or ".git" in parts:
                continue

            mode = (info.external_attr >> 16) & 0xFFFF
            file_type = stat.S_IFMT(mode)
            is_directory = info.is_dir() or file_type == stat.S_IFDIR
            if file_type not in {0, stat.S_IFREG, stat.S_IFDIR}:
                raise ValueError(
                    f"ZIP entry is not a regular file or directory: {info.filename!r}"
                )

            key = "/".join(parts)
            if key in seen:
                raise ValueError(f"ZIP archive contains a duplicate path: {key!r}")
            for index in range(1, len(parts)):
                parent_key = "/".join(parts[:index])
                if seen.get(parent_key) is False:
                    raise ValueError(
                        f"ZIP path is nested beneath a file: {info.filename!r}"
                    )
            if not is_directory and any(
                existing.startswith(key + "/") for existing in seen
            ):
                raise ValueError(f"ZIP file conflicts with a directory: {key!r}")
            seen[key] = is_directory

            output = destination.joinpath(*parts)
            try:
                output.resolve().relative_to(destination)
            except ValueError as exc:
                raise ValueError(
                    f"ZIP entry escapes the archive root: {info.filename!r}"
                ) from exc

            if is_directory:
                output.mkdir(parents=True, exist_ok=True)
                output.chmod(0o755)
                continue

            output.parent.mkdir(parents=True, exist_ok=True)
            written = 0
            with archive_file.open(info, "r") as source, output.open("xb") as target:
                while True:
                    chunk = source.read(1024 * 1024)
                    if not chunk:
                        break
                    written += len(chunk)
                    extracted_bytes += len(chunk)
                    if (
                        written > info.file_size
                        or extracted_bytes > MAX_ZIP_UNCOMPRESSED_BYTES
                    ):
                        raise ValueError("ZIP archive exceeded its declared extraction size")
                    target.write(chunk)
            output.chmod(0o755 if mode & 0o111 else 0o644)

    files = [path for path in destination.rglob("*") if path.is_file()]
    if not files:
        raise ValueError("ZIP archive does not contain any repository files")

    children = list(destination.iterdir())
    if len(children) == 1 and children[0].is_dir():
        return children[0]
    return destination


def create_repository_from_zip(root, archive_path, default_branch, staged_repo):
    root = Path(root)
    with tempfile.TemporaryDirectory(prefix="git-remote-zip-", dir=str(root)) as tmp:
        temp_root = Path(tmp)
        try:
            source = extract_zip_source(archive_path, temp_root / "source")
        except (zipfile.BadZipFile, NotImplementedError) as exc:
            raise ValueError(f"Invalid ZIP archive: {archive_path}") from exc
        work = temp_root / "work"
        shutil.copytree(source, work)
        run(["git", "init", str(work)], env=git_env())
        run(["git", "-C", str(work), "config", "user.name", "Taylor Chen"])
        run(
            [
                "git",
                "-C",
                str(work),
                "config",
                "user.email",
                "taylor.chen@company.com",
            ]
        )
        run(
            [
                "git",
                "-C",
                str(work),
                "symbolic-ref",
                "HEAD",
                f"refs/heads/{default_branch}",
            ],
            env=git_env(),
        )
        run(["git", "-C", str(work), "add", "-A"], env=git_env())
        run(
            ["git", "-C", str(work), "commit", "-m", "Import repository archive"],
            env=git_env(),
        )
        run(["git", "clone", "--bare", str(work), str(staged_repo)], env=git_env())


def create_repository(
    root,
    repo_rel,
    *,
    from_template=False,
    from_zip=None,
    default_branch="main",
    replace=False,
):
    if from_template and from_zip is not None:
        raise ValueError("--from-template and --from-zip cannot be used together")
    run(["git", "check-ref-format", "--branch", default_branch])
    root = Path(root)
    root.mkdir(parents=True, exist_ok=True)
    clean_rel, repo = repository_location(root, repo_rel)
    if repo.is_symlink():
        raise ValueError("repository path must not be a symbolic link")
    if repo.exists():
        if not replace:
            raise FileExistsError(f"repository already exists: {clean_rel}")

    repo.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="git-remote-create-", dir=str(root)) as tmp:
        temp_root = Path(tmp)
        staged_repo = temp_root / "repository.git"
        if from_zip is not None:
            create_repository_from_zip(root, from_zip, default_branch, staged_repo)
        elif from_template:
            template = ensure_template(root)
            run(["git", "clone", "--bare", str(template), str(staged_repo)], env=git_env())
            if default_branch != "main":
                main_commit = subprocess.run(
                    ["git", "--git-dir", str(staged_repo), "rev-parse", "refs/heads/main"],
                    check=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                ).stdout.strip()
                run(
                    [
                        "git",
                        "--git-dir",
                        str(staged_repo),
                        "update-ref",
                        f"refs/heads/{default_branch}",
                        main_commit,
                    ],
                    env=git_env(),
                )
        else:
            run(["git", "init", "--bare", str(staged_repo)], env=git_env())

        run(
            [
                "git",
                "--git-dir",
                str(staged_repo),
                "symbolic-ref",
                "HEAD",
                f"refs/heads/{default_branch}",
            ],
            env=git_env(),
        )
        run(
            ["git", "--git-dir", str(staged_repo), "config", "http.receivepack", "true"],
            env=git_env(),
        )
        run(["git", "--git-dir", str(staged_repo), "update-server-info"], env=git_env())

        previous_repo = temp_root / "previous.git"
        if repo.exists():
            os.replace(repo, previous_repo)
        try:
            os.replace(staged_repo, repo)
        except Exception:
            if previous_repo.exists() and not repo.exists():
                os.replace(previous_repo, repo)
            raise
    return clean_rel, repo


def ensure_repository(root, repo_rel, *, create_empty_if_missing=False):
    clean_rel, repo = repository_location(root, repo_rel)
    if not (repo / "HEAD").is_file():
        if not create_empty_if_missing:
            return clean_rel, repo
        create_repository(root, clean_rel)
    run(["git", "--git-dir", str(repo), "config", "http.receivepack", "true"], env=git_env())
    run(["git", "--git-dir", str(repo), "update-server-info"], env=git_env())
    return clean_rel, repo


def is_receive_pack_request(parsed):
    services = urllib.parse.parse_qs(parsed.query).get("service", [])
    return (
        "git-receive-pack" in services
        or parsed.path.rstrip("/").endswith("/git-receive-pack")
    )


def split_headers(raw):
    if b"\r\n\r\n" in raw:
        return raw.split(b"\r\n\r\n", 1)
    if b"\n\n" in raw:
        return raw.split(b"\n\n", 1)
    return raw, b""


def parse_status(value):
    try:
        return int(value.strip().split(" ", 1)[0])
    except Exception:
        return 200


def make_handler(root):
    root = str(Path(root).resolve())
    repos = str((Path(root) / "repositories").resolve())

    class GitHandler(BaseHTTPRequestHandler):
        server_version = "GitRemoteHTTP/2.0"

        def log_message(self, fmt, *args):
            sys.stderr.write("%s - - [%s] %s\n" % (self.address_string(), self.log_date_time_string(), fmt % args))

        def do_GET(self):
            self.handle_request()

        def do_HEAD(self):
            self.handle_request()

        def do_POST(self):
            self.handle_request()

        def handle_request(self):
            parsed = urllib.parse.urlsplit(self.path)
            if parsed.path == "/health":
                body = json.dumps({"status": "ok", "service": "git-remote", "version": "2.0.0"}).encode("utf-8")
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                if self.command != "HEAD":
                    self.wfile.write(body)
                return

            repo_rel = repo_part_from_path(parsed.path)
            clean_rel, _repo = ensure_repository(
                root,
                repo_rel,
                create_empty_if_missing=is_receive_pack_request(parsed),
            )
            suffix = parsed.path[len("/" + repo_rel.strip("/")) :] if parsed.path.startswith("/" + repo_rel.strip("/")) else ""
            if not suffix:
                suffix = "/info/refs"
            path_info = "/" + clean_rel + suffix

            length = int(self.headers.get("Content-Length", "0") or "0")
            request_body = self.rfile.read(length) if length else b""
            env = os.environ.copy()
            env.update(
                {
                    "GIT_PROJECT_ROOT": repos,
                    "GIT_HTTP_EXPORT_ALL": "1",
                    "GIT_HTTP_RECEIVEPACK": "1",
                    "REQUEST_METHOD": self.command,
                    "PATH_INFO": path_info,
                    "QUERY_STRING": parsed.query,
                    "CONTENT_TYPE": self.headers.get("Content-Type", ""),
                    "CONTENT_LENGTH": str(length),
                    "REMOTE_ADDR": self.client_address[0],
                    "SERVER_PROTOCOL": self.protocol_version,
                }
            )
            proc = subprocess.Popen(
                ["git", "http-backend"],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                env=env,
            )
            out, err = proc.communicate(request_body, timeout=60)
            if proc.returncode != 0 and not out:
                body = (err or b"git http-backend failed").strip() + b"\n"
                self.send_response(500)
                self.send_header("Content-Type", "text/plain")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                if self.command != "HEAD":
                    self.wfile.write(body)
                return

            header_blob, body = split_headers(out)
            status = 200
            headers = []
            for line in header_blob.decode("iso-8859-1", errors="replace").splitlines():
                if not line.strip():
                    continue
                key, sep, value = line.partition(":")
                if not sep:
                    continue
                if key.lower() == "status":
                    status = parse_status(value)
                else:
                    headers.append((key.strip(), value.strip()))

            self.send_response(status)
            has_length = False
            for key, value in headers:
                if key.lower() == "content-length":
                    has_length = True
                self.send_header(key, value)
            if not has_length:
                self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            if self.command != "HEAD":
                self.wfile.write(body)

    return GitHandler


def serve(host, port, root):
    root = Path(root)
    root.mkdir(parents=True, exist_ok=True)
    if not shutil.which("git"):
        raise SystemExit("git executable not found")
    ensure_template(root)
    server = ThreadingHTTPServer((host, port), make_handler(root))
    print(f"git remote service listening on {host}:{server.server_port}", flush=True)
    server.serve_forever()


def main():
    parser = argparse.ArgumentParser(description="Serve local Git repositories over smart HTTP.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=18773)
    parser.add_argument("--root", default="/var/lib/git-remote")
    parser.add_argument("--version", action="store_true")
    args = parser.parse_args()
    if args.version:
        print("2.0.0")
        return 0
    serve(args.host, args.port, args.root)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
