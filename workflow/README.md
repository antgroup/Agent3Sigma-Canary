# AgentCanary Workflow

`workflow/` builds the seven safety-research evaluation images. Other image
directories provide build contexts reused by those variants.

## Image Roles

| Image Type | Tag Format | Description |
|------------|------------|-------------|
| `official_safety_research` | `openclaw-official_safety_research-v{timestamp}` | `official` + LibreOffice headless document tooling + OpenSSH/rsync |
| `official_newest_safety_research` | `openclaw-official_newest_safety_research-v{timestamp}` | `official_safety_research` with OpenClaw `2026.7.1-2` |
| `official_newest_shield_safety_research` | `openclaw-official_newest_shield_safety_research-v{timestamp}` | `official_newest_safety_research` + openclaw-shield |
| `hermes_safety_research` | `openclaw-hermes_safety_research-v{timestamp}` | Hermes + safety-research tools and skills |
| `nanoclaw_safety_research` | `openclaw-nanoclaw_safety_research-v{timestamp}` | NanoClaw + safety-research tools and skills |
| `claude_code_safety_research` | `openclaw-claude_code_safety_research-v{timestamp}` | Claude Code + safety-research tools and skills |
| `codex_safety_research` | `openclaw-codex_safety_research-v{timestamp}` | Codex + safety-research tools and skills |

The `official`, `claude_code`, `codex`, `hermes`, and `nanoclaw` directories
provide reusable contexts; `safety_research_overlay` adds shared research
tooling. They are retained as dependencies, not offered in the build menu.

## Directory Layout

```text
workflow/
├── README.md
├── workflow_step_1_image_builder.sh
└── images/
    ├── official/
    │   ├── Dockerfile
    │   ├── openclaw.json
    │   ├── prepare.sh
    │   └── mock-api/
    ├── official_safety_research/
    │   ├── Dockerfile
    │   └── prepare.sh
    ├── official_newest_safety_research/
    │   ├── Dockerfile
    │   └── prepare.sh
    ├── official_newest_shield_safety_research/
    │   ├── openclaw-shield/
    │   ├── mock-api/
    │   ├── mock_api_data/
    │   ├── mock_api_handlers/
    │   ├── wordpress-runtime-smoke.sh
    │   ├── Dockerfile
    │   └── prepare.sh
    ├── claude_code_safety_research/
    ├── codex_safety_research/
    ├── hermes_safety_research/
    ├── nanoclaw_safety_research/
    ├── claude_code/           # Shared runtime context
    ├── codex/                 # Shared runtime context
    ├── hermes/                # Shared runtime context
    ├── nanoclaw/              # Shared runtime context
    └── safety_research_overlay/  # Shared research tooling
```

`openclaw.json` is generated from `config.yaml` by `bash setup.sh`
(`scripts/generate_config.py`) before image preparation; it is not committed.

## Build Flow

```text
workflow_step_1_image_builder.sh
├── Creates the workspace directory .workspaces/AgentCanary_{timestamp}
├── Selects image types
├── Calls images/{type}/prepare.sh to prepare the build context
└── Runs docker build
```

Build outputs:

- Workspace: `.workspaces/AgentCanary_{timestamp}`
- Build context: `.workspaces/AgentCanary_{timestamp}/build_{type}`
- Image tag: `openclaw-{type}-v{timestamp}`
- State file: `.workspaces/AgentCanary_{timestamp}/.build_state`

## Usage

```bash
bash workflow/workflow_step_1_image_builder.sh
```

Interactive prompts:

| Prompt | Default When Pressing Enter |
|--------|-----------------------------|
| Workspace selection | Create a new workspace |
| Proxy configuration | Do not use a proxy |
| Image type selection | Build all image types |

## official Build Contents

`images/official/prepare.sh` copies the following files into the Docker build context:

- `images/official/Dockerfile`
- `images/official/openclaw.json`
- `assets/mock_api/data`
- `assets/mock_api/api_handlers`
- `images/official/mock-api`

`images/official/Dockerfile` installs and configures:

- `openclaw@2026.4.11`
- mock-api server: `/opt/mock-api`
- mock-api data: `/tmp/scry/mock_api/data`

Skills are mounted read-only per task, and each selected skill's `skill_data`
is copied into the running container separately. Compatibility runtimes also
receive the same skill at their native discovery path.

## official_safety_research Build Contents

`images/official_safety_research/prepare.sh` first reuses `images/official/prepare.sh` to generate a complete official build context, then replaces only the Dockerfile.

The image keeps the official OpenClaw, skill injection, and mock-api behavior, bakes in the ClawHub
`pandoc@1.0.2` skill under `/root/.openclaw/skills/pandoc`, and additionally installs:

- `openssh-server`
- `rsync`
- `python3`
- `python3-pip`
- Python packages: `matplotlib`, `jupyter`
- PHP CLI and common WordPress PHP extensions
- WP-CLI (`wp`)
- WordPress Playground CLI (`wp-playground-cli`)
- `libreoffice`
- `pandoc`
- `weasyprint`
- `fonts-noto-cjk`
- `fonts-liberation`
- `fontconfig`

At runtime, `scripts/lib_docker.py` treats image tags containing `official_safety_research`
as open-egress research images and skips the AgentCanary iptables egress lockdown for them.
Other images keep the default outbound allowlist.

`images/official_newest_safety_research/prepare.sh` reuses this complete build
context and replaces only the Dockerfile. Its sole runtime difference is the
OpenClaw pin: `2026.7.1-2` instead of `2026.4.11`.

`images/official_newest_shield_safety_research/` contains its own copy of the
complete newest safety-research Dockerfile, mock API, WordPress smoke script,
mock data, and Shield source. Its prepare script does not read another image
directory. The Dockerfile builds the same OpenClaw `2026.7.1-2` research
runtime and additionally compiles and installs Shield for the newer plugin
loader. It does not require a prebuilt safety-research image.

Select `[3]` in `workflow_step_1_image_builder.sh` to build this variant.

The intended use is headless document work through the existing full tool profile, for example:

```bash
libreoffice --headless --convert-to pdf report.docx --outdir /workspace
soffice --headless --convert-to txt report.docx --outdir /workspace
wordpress-runtime-smoke
```

## Hermes, NanoClaw, Claude Code, and Codex Build Contents

Each safety-research variant first runs its matching shared runtime
`prepare.sh`, then applies `safety_research_overlay/prepare.sh` and its own
Dockerfile. The overlay also reads
`official_safety_research/wordpress-runtime-smoke.sh`. The shared runtime
contexts include the framework shims and mock API files needed by the final
images. Skills and skill data are injected per task.

## Resume Support

The build script supports resuming interrupted builds:

- State is saved in `{WORK_DIR}/.build_state`
- When rerun after interruption, the script detects existing workspaces
- The user can continue, overwrite the existing workspace, or create a new workspace
