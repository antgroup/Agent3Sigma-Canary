# AgentCanary Workflow

`workflow/` builds AgentCanary images by combining an agent framework, an OpenClaw version (for official variants), and an optional shared safety research tool layer.

## Image Roles

| Image Type | Tag Format | Description |
|------------|------------|-------------|
| `official` | `openclaw-official-v{timestamp}` | Native OpenClaw + custom skills + mock-api server |
| `official_shield` | `openclaw-official_shield-v{timestamp}` | `official` + openclaw-shield security plugin |
| `official_secureclaw` | `openclaw-official_secureclaw-v{timestamp}` | `official` + SecureClaw security plugin |
| `official_clawkeeper` | `openclaw-official_clawkeeper-v{timestamp}` | `official` + ClawKeeper security plugin |
| `hermes` | `openclaw-hermes-v{timestamp}` | hermes-agent (Nous Research) framework wrapped behind an `openclaw` shim + mock-api server |
| `claude_code` | `openclaw-claude_code-v{timestamp}` | Claude Code CLI + native history/skill adapter + mock API |
| `codex` | `openclaw-codex-v{timestamp}` | Codex CLI + native history/skill adapter + mock API |
| `nanoclaw` | `openclaw-nanoclaw-v{timestamp}` | nanoclaw runtime (Claude Agent SDK) wrapped behind an `openclaw` shim + mock-api server |

The `official_*` variants extend `official` by adding different security plugins. The `hermes` and `nanoclaw` variants instead wrap third-party agent frameworks behind an `openclaw` shim so they can be evaluated through the same harness.

## Directory Layout

```text
workflow/
├── README.md
├── workflow_step_1_image_builder.sh
├── build_images.py
├── features/safety_research/  # Shared optional tools and skills
└── images/
    ├── claude_code/
    ├── codex/
    ├── official/
    │   ├── Dockerfile
    │   ├── openclaw.json
    │   ├── prepare.sh
    │   └── mock-api/
    ├── official_shield/
    │   ├── Dockerfile
    │   ├── openclaw.json
    │   └── prepare.sh
    ├── official_secureclaw/
    │   ├── secureclaw/
    │   ├── Dockerfile
    │   ├── openclaw.json
    │   └── prepare.sh
    ├── official_clawkeeper/
    │   ├── ClawKeeper/
    │   ├── Dockerfile
    │   ├── openclaw.json
    │   └── prepare.sh
    ├── hermes/
    │   ├── Dockerfile
    │   ├── openclaw.overrides.json
    │   ├── prepare.sh
    │   ├── shim/openclaw
    │   └── mock-api/
    └── nanoclaw/
        ├── Dockerfile
        ├── openclaw.overrides.json
        ├── prepare.sh
        ├── shim/            # openclaw + driver.mjs
        └── mock-api/
```

> `openclaw.json` is not committed for any variant — it is generated from `config.yaml` by `bash setup.sh` (`scripts/generate_config.py`) before the build.

## Build Flow

```text
workflow_step_1_image_builder.sh
├── Creates the workspace directory .workspaces/AgentCanary_{timestamp}
├── Selects image types, OpenClaw version, and optional research tools
├── Calls images/{type}/prepare.sh to prepare the build context
├── Composes the shared research layer when requested
└── Runs docker build (or stops after --prepare-only)
```

Build outputs:

- Workspace: `.workspaces/AgentCanary_{timestamp}`
- Build context: `.workspaces/AgentCanary_{timestamp}/build_{type}`
- Image tag: `openclaw-{type}[-openclaw-{version}][-safety_research]-v{timestamp}`; the default OpenClaw version omits the version suffix
- State file: `.workspaces/AgentCanary_{timestamp}/.build_state.json`

## Usage

```bash
bash workflow/workflow_step_1_image_builder.sh
```

Without flags, a terminal session asks for agent types, OpenClaw version, and research tools. Defaults are `official`, OpenClaw `2026.4.11`, and no research layer. Noninteractive invocations use the same defaults.

```bash
# Newer OpenClaw and Shield, with the shared research environment.
bash workflow/workflow_step_1_image_builder.sh \
  --images official,official_shield --openclaw-version 2026.7.1-2 \
  --safety-research --non-interactive

# Claude Code and Codex, using the same optional tool layer.
bash workflow/workflow_step_1_image_builder.sh \
  --images claude_code,codex --safety-research --non-interactive

# Stage contexts without Docker, package downloads, or image builds.
bash workflow/workflow_step_1_image_builder.sh \
  --images codex --prepare-only --workspace /tmp/canary-codex-context

# Build prepared contexts or resume after an interrupted/failed build.
bash workflow/workflow_step_1_image_builder.sh --resume /tmp/canary-codex-context
```

`--images` accepts names, menu numbers, or `all`. `--openclaw-version newest` is a reproducible alias for `2026.7.1-2`, not a moving registry tag. `--no-safety-research` explicitly disables the optional layer. `--proxy URL` retains Linux host networking and Docker Desktop localhost rewriting. `--workspace` must name an empty/new directory; the builder never deletes an existing workspace.

The shared research layer installs document conversion, OCR, accounting, backup, network/operations, PII, and WordPress tools. It includes selected local skills and downloads pinned community skills during Docker build. It is shared by all frameworks, without separate `*_safety_research` image directories. A version/profile-specific tag and image labels identify the resulting runtime.

## Claude Code and Codex

The CLI versions default to Claude Code `2.1.190` and Codex `0.145.0`, matching the imported NARA adapters. Each shim translates native tool calls/results into the existing benchmark transcript format, mounts skills at its native discovery path, and supports `seed_history` by constructing a native session.

- Claude Code requires an Anthropic-compatible target endpoint. `CLAUDE_PERMISSION_MODE=auto` (default) enables its automatic permission review; `bypass` selects its bypass mode.
- Codex requires an OpenAI-compatible **Responses API** endpoint. `CODEX_BASE_URL` can override the configured endpoint; `CODEX_PERMISSION_MODE=auto-review` (default) enables automatic approval review, while `yolo` bypasses the CLI sandbox/approvals.
- Target `--effort` is forwarded to the native runtime. Judge effort is configured independently with `roles.judge.effort`.
- `--gateway` applies to official OpenClaw variants; the other frameworks use their native CLIs.

Codex containers receive the seccomp/AppArmor exceptions required by the CLI's nested sandbox. Other frameworks retain Docker's default profiles.

## official Build Contents

`images/official/prepare.sh` copies the following files into the Docker build context:

- `images/official/Dockerfile`
- `images/official/openclaw.json`
- `assets/mock_api/data`
- `assets/mock_api/api_handlers`
- `images/official/mock-api`

`images/official/Dockerfile` installs and configures:

- `openclaw@2026.4.11` by default, configurable through `--openclaw-version`
- mock-api server: `/opt/mock-api`
- mock-api data: `/tmp/scry/mock_api/data`

Skills are bind-mounted and their `skill_data` is copied into each container
only for the task that requires them. The same per-task injection path is used
by every image type; compatibility images additionally receive the mount at
their native skill-discovery location.

At runtime, benchmark runs keep outbound networking open by default. Passing
`benchmark.py --netlock` asks `scripts/lib_docker.py` to apply the
AgentCanary iptables allowlist. Research-profile images (identified by the `safety_research` tag or builder label) skip that lockdown by default. Set `DOCKER_OPEN_EGRESS_IMAGE_PATTERNS=""` to apply `--netlock` to research profiles as well.

## Newer OpenClaw Runtime

OpenClaw `2026.7.1-2` uses local CLI execution when no Gateway was started by the runner; `--gateway` uses the native Gateway instead. Image metadata selects this behavior even when an image is retagged. Conversation loading excludes `*.trajectory.jsonl` telemetry. The local CLI wrapper cleans up a lingering process group after a terminal trajectory event. The adapter also passes `--effort max` through the provider request when OpenClaw's model-name validation would reject it.

## official_shield Build Contents

`images/official_shield/prepare.sh` first reuses `images/official/prepare.sh` to generate a complete official build context, then adds:

- `openclaw-shield` source code: `/opt/openclaw-shield`
- Dockerfile installation step: `openclaw plugins install /opt/openclaw-shield`; newer OpenClaw builds first compile the plugin to JavaScript with pinned esbuild and update its extension entrypoint
- `tools.profile = "full"` in `openclaw.json`, so `knostic_shield` is included in the agent's actual tool list

`official_shield/openclaw.json` remains consistent with `official/openclaw.json` and does not manually add plugin configuration.

The plugin source code must be cloned in advance. The build does not access GitHub.
The default source location is:

```text
workflow/images/official_shield/openclaw-shield
```

You can also specify another local source directory with an environment variable:

```bash
OPENCLAW_SHIELD_SOURCE_DIR=/path/to/openclaw-shield \
  bash workflow/workflow_step_1_image_builder.sh
```

## official_secureclaw Build Contents

`images/official_secureclaw/prepare.sh` first reuses `images/official/prepare.sh` to generate a complete official build context, then adds:

- `secureclaw` repository source code: `/opt/secureclaw`
- Source installation following `Option C: Plugin from source` in the SecureClaw README:
  - `cd /opt/secureclaw/secureclaw`
  - `npm install`
  - `npm run build`
  - `npx openclaw plugins install -l .`
- Built-in SecureClaw skill installation: `npx openclaw secureclaw skill install`

`official_secureclaw/openclaw.json` remains consistent with `official/openclaw.json` and does not manually add plugin configuration.

The plugin source code has been cloned to:

```text
workflow/images/official_secureclaw/secureclaw
```

You can also specify another local source directory with an environment variable:

```bash
SECURECLAW_SOURCE_DIR=/path/to/secureclaw \
  bash workflow/workflow_step_1_image_builder.sh
```

## official_clawkeeper Build Contents

`images/official_clawkeeper/prepare.sh` first reuses `images/official/prepare.sh` to generate a complete official build context, then adds:

- `ClawKeeper` plugin source code: `/opt/ClawKeeper/clawkeeper-plugin`
- `plugins.load.paths = ["/opt/ClawKeeper/clawkeeper-plugin"]` in `openclaw.json`

ClawKeeper's `install.sh` runs `npx openclaw plugins install -l .` internally, but OpenClaw's install-time scan blocks installation because the plugin contains `child_process` shell command execution patterns.
This image therefore loads the local plugin path explicitly through `openclaw.json`.

The plugin source code has been cloned to:

```text
workflow/images/official_clawkeeper/ClawKeeper
```

You can also specify another local source directory with an environment variable:

```bash
CLAWKEEPER_SOURCE_DIR=/path/to/ClawKeeper \
  bash workflow/workflow_step_1_image_builder.sh
```

## hermes / nanoclaw Build Contents

`hermes` and `nanoclaw` wrap third-party agent frameworks so they can be evaluated through the same harness as `official`. Each image ships:

- A custom `/usr/local/bin/openclaw` shim (`images/{type}/shim/openclaw`) that translates AgentCanary's `openclaw agent ...` calls into the framework's native entrypoint — hermes via `run_agent.py`, nanoclaw via the Claude Agent SDK `query` API (`shim/driver.mjs`).
- A `mock-api` sidecar, matching the `official` image.
- `openclaw.overrides.json` (empty `{}` by default).

As with every variant, `openclaw.json` is not committed: it is generated from `config.yaml` by `bash setup.sh` (`scripts/generate_config.py`) before the build, then copied into the build context by `prepare.sh`.

## Resume Support

Build options and completed images are saved atomically in `{WORK_DIR}/.build_state.json`. Use `--resume WORK_DIR` to reuse those exact options. Completed images are inspected and skipped; failed or missing images are rebuilt. To change framework/version/profile options, use a new workspace. `--prepare-only` never marks images as built.

Legacy `.build_state` shell files remain untouched. Create a new workspace for this builder instead of loading those older state files.
