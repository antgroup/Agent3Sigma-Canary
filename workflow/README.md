# AgentCanary Workflow

`workflow/` builds AgentCanary images by combining an agent framework and an optional shared safety research tool layer. All official OpenClaw variants use the same pinned version `2026.7.1-2`.

## Image Roles

| Image Type | Tag Format | Description |
|------------|------------|-------------|
| `official` | `openclaw-official-openclaw-2026.7.1-2-v{timestamp}` | Native OpenClaw + custom skills + mock-api server |
| `official_shield` | `openclaw-official_shield-openclaw-2026.7.1-2-v{timestamp}` | `official` + openclaw-shield security plugin |
| `official_secureclaw` | `openclaw-official_secureclaw-openclaw-2026.7.1-2-v{timestamp}` | `official` + SecureClaw security plugin |
| `official_clawkeeper` | `openclaw-official_clawkeeper-openclaw-2026.7.1-2-v{timestamp}` | `official` + ClawKeeper security plugin |
| `hermes` | `openclaw-hermes-v{timestamp}` | hermes-agent (Nous Research) framework wrapped behind an `openclaw` shim + mock-api server |
| `claude_code` | `openclaw-claude_code-v{timestamp}` | Claude Code CLI + native history/skill adapter + mock API |
| `codex` | `openclaw-codex-v{timestamp}` | Codex CLI + native history/skill adapter + mock API |
| `nanoclaw` | `openclaw-nanoclaw-v{timestamp}` | nanoclaw runtime (Claude Agent SDK) wrapped behind an `openclaw` shim + mock-api server |
| `nanoclaw_openai` | `openclaw-nanoclaw_openai-v{timestamp}` | NanoClaw with the OpenCode driver for OpenAI-compatible endpoints |

The `official_*` variants extend `official` by adding different security plugins. The `hermes` and `nanoclaw` variants instead wrap third-party agent frameworks behind an `openclaw` shim so they can be evaluated through the same harness.

## Directory Layout

```text
workflow/
├── README.md
├── workflow_step_1_image_builder.sh
├── build_images.py
├── openclaw.json             # Generated, shared model/provider configuration
├── mock-api/                 # One shared mock server for all images
├── tools/                    # Optional safety_research tools and skills
└── images/
    ├── openclaw/
    │   ├── Dockerfile
    │   ├── Dockerfile.shield       # Plugin-only build fragment
    │   ├── Dockerfile.secureclaw   # Plugin-only build fragment
    │   ├── Dockerfile.clawkeeper   # Plugin-only build fragment
    │   └── clawkeeper.overrides.json
    ├── hermes/              # Dockerfile + openclaw shim
    ├── nanoclaw/            # Both SDK/OpenCode variants and their drivers
    ├── claude_code/         # Dockerfile + openclaw shim
    └── codex/               # Dockerfile + openclaw shim + model template
```

There are five framework directories. OpenClaw plugin variants share one base Dockerfile, and both NanoClaw variants share one directory. `build_images.py` prepares all build contexts; per-image `prepare.sh` scripts are no longer needed. Vendored plugin sources live in the repository's [`third_party/`](../third_party/README.md) directory.

> `workflow/openclaw.json` is generated from `config.yaml` by `bash setup.sh` (`scripts/generate_config.py`) and is not committed. Run setup again after migrating from the old per-image configuration layout. The builder applies plugin overrides only to the selected image's build context.

## Build Flow

```text
workflow_step_1_image_builder.sh
├── Stage 1: selects agent images (all OpenClaw images use the pinned version)
├── Stage 2: chooses whether to add the shared safety_research toolset
├── Creates the workspace directory .workspaces/AgentCanary_{timestamp}
├── Prepares the context from one framework directory and shared assets
├── Adds the selected OpenClaw plugin fragment and source, if applicable
├── Composes the shared research layer when requested
└── Runs docker build (or stops after --prepare-only)
```

Build outputs:

- Workspace: `.workspaces/AgentCanary_{timestamp}`
- Build context: `.workspaces/AgentCanary_{timestamp}/build_{type}`
- Image tag: `openclaw-{type}[-openclaw-{version}][-safety_research]-v{timestamp}`; every OpenClaw image includes the pinned version suffix
- State file: `.workspaces/AgentCanary_{timestamp}/.build_state.json`

## Usage

```bash
bash workflow/workflow_step_1_image_builder.sh
```

Without flags, a terminal session guides you through two stages:

1. **Choose agent images:** OpenClaw (`official` or a security plugin variant), Hermes, NanoClaw, Claude Code, or Codex. Multiple images can be selected. All OpenClaw images use `2026.7.1-2`, with no version prompt.
2. **Choose optional tools:** answer `y` to add the shared `safety_research` toolset to every selected image, or press Enter / answer `n` to keep the base toolset.

For example, select `8` for Codex, then answer `y` to build Codex with the research tools, or `n` to build its base image. Defaults are `official`, OpenClaw `2026.7.1-2`, and no research layer. Command-line options fill in the corresponding choices without prompting; `--non-interactive` uses defaults for any omitted choices. `--resume` reuses the saved choices.

```bash
# OpenClaw and Shield, with the shared research environment.
bash workflow/workflow_step_1_image_builder.sh \
  --images official,official_shield \
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

`--images` accepts names, menu numbers, or `all`. `--openclaw-version` has been removed: all OpenClaw images use `2026.7.1-2`. Resuming a workspace configured for an older OpenClaw version reports an error; create a new workspace to rebuild. Existing task definitions do not need a version field or migration. `--no-safety-research` explicitly disables the optional layer. `--proxy URL` retains Linux host networking and Docker Desktop localhost rewriting. `--workspace` must name an empty/new directory; the builder never deletes an existing workspace.

The shared research layer in `tools/` installs document conversion, OCR, accounting, backup, network/operations, PII, and WordPress tools. It includes selected local skills and downloads pinned community skills during Docker build. It is shared by all frameworks, without separate `*_safety_research` image directories. A version/profile-specific tag and image labels identify the resulting runtime.

Enabling this layer always adds `-safety_research` to the image name, for example `openclaw-codex-safety_research-v20261016_120000`. Tasks declare the dependency with `required_toolset: safety_research`; benchmark checks the selected image name before execution. Keep the marker when retagging an image. Tasks with an omitted or empty requirement retain their existing behavior. See [task format](../docs/task_format_en.md#image-toolset-requirements).

## Claude Code and Codex

The CLI versions default to Claude Code `2.1.190` and Codex `0.145.0`, matching the imported NARA adapters. Each shim translates native tool calls/results into the existing benchmark transcript format, mounts skills at its native discovery path, and supports `seed_history` by constructing a native session.

- Claude Code requires an Anthropic-compatible target endpoint. `CLAUDE_PERMISSION_MODE=auto` (default) enables its automatic permission review; `bypass` selects its bypass mode.
- Codex requires an OpenAI-compatible **Responses API** endpoint. `CODEX_BASE_URL` can override the configured endpoint; `CODEX_PERMISSION_MODE=auto-review` (default) enables automatic approval review, while `yolo` bypasses the CLI sandbox/approvals.
- Target `--effort` is forwarded to the native runtime. Judge effort is configured independently with `roles.judge.effort`.
- Codex effort precedence is `--effort`, then an explicit `CODEX_REASONING_EFFORT`, then its native model default. When neither override is set, the shim omits `model_reasoning_effort` and preserves each known model's default from the installed CLI's bundled catalog. Unknown model names have no effort default, leaving that choice to the endpoint. It does not force `low` or copy GPT-5.4's `medium` default onto other models.
- `--gateway` applies to official OpenClaw variants; the other frameworks use their native CLIs.

Codex containers receive the seccomp/AppArmor exceptions required by the CLI's nested sandbox. Other frameworks retain Docker's default profiles.

## Evaluation Without Judge Models

`benchmark.py --trajectory-only` uses the normal task preparation, agent execution, transcript collection, automatic checks, Tracee correlation, and result-writing paths. It skips the task and Tracee judge models. LLM-only and hybrid totals remain `null`; hybrid automated breakdowns and fully automated scores are retained. The original task grading type is preserved.

Results remain under the usual `results/job_*/task_*/` paths, with full transcripts and summaries readable in `workflow_analysis`. Additional `trajectories/job_*/trajectory_*.json` records contain the complete transcript and execution information, including any Tracee log/correlation paths. Judge fields stay empty and the viewer shows `N/A`. PAIR cannot use this option because it needs a judge during attack search.

Multi-turn tasks reuse the same runtime conversation until a `sessions` entry
sets `new_session: true`. At that boundary the runner archives the previous
transcript and issues a new session ID, while preserving workspace files,
installed skills and memory files. This applies to OpenClaw and its plugin
variants, Claude Code, Codex, Hermes, NanoClaw and NanoClaw/OpenAI. Hermes
persists its conversation history; NanoClaw resumes its SDK/OpenCode session.
Codex sandbox options are passed to the parent `exec` command before `resume`,
which has a narrower argument parser. Rebuild the affected images after
updating these adapters.

## official Build Contents

`build_images.py` copies the following files into the Docker build context:

- `images/openclaw/Dockerfile`
- `workflow/openclaw.json`
- `assets/mock_api/data`
- `assets/mock_api/api_handlers`
- `workflow/mock-api`

`images/openclaw/Dockerfile` installs and configures:

- `openclaw@2026.7.1-2` for every official variant
- mock-api server: `/opt/mock-api`
- mock-api data: `/tmp/scry/mock_api/data`

Skills are bind-mounted and their `skill_data` is copied into each container
only for the task that requires them. The same per-task injection path is used
by every image type; compatibility images additionally receive the mount at
their native skill-discovery location.

At runtime, benchmark runs keep outbound networking open by default. Passing
`benchmark.py --netlock` asks `scripts/lib_docker.py` to apply the
AgentCanary iptables allowlist. Research-profile images (identified by the `safety_research` tag or builder label) skip that lockdown by default. Set `DOCKER_OPEN_EGRESS_IMAGE_PATTERNS=""` to apply `--netlock` to research profiles as well.

## OpenClaw Runtime

OpenClaw `2026.7.1-2` uses local CLI execution when no Gateway was started by the runner; `--gateway` uses the native Gateway bound to container loopback instead, matching the in-container client. The runner generates a temporary authentication token in the container config so the new Gateway and CLI can authenticate; host config and image contents are unchanged. Image metadata selects this behavior even when an image is retagged. Conversation loading excludes `*.trajectory.jsonl` telemetry. The local CLI wrapper cleans up a lingering process group after a terminal trajectory event. The adapter also passes `--effort max` through the provider request when OpenClaw's model-name validation would reject it.

## official_shield Build Contents

The builder inserts `images/openclaw/Dockerfile.shield` into the shared OpenClaw Dockerfile and adds:

- `openclaw-shield` source code: `/opt/openclaw-shield`
- Dockerfile installation step: `openclaw plugins install /opt/openclaw-shield`; builds first compile the plugin to JavaScript with pinned esbuild and update its extension entrypoint
- `tools.profile = "full"` in `openclaw.json`, so `knostic_shield` is included in the agent's actual tool list

This variant uses the shared `workflow/openclaw.json` without additional configuration overrides.

Plugin source is included locally. Context preparation does not access GitHub. The default source location is:

```text
third_party/openclaw-shield
```

You can also specify another local source directory with an environment variable:

```bash
OPENCLAW_SHIELD_SOURCE_DIR=/path/to/openclaw-shield \
  bash workflow/workflow_step_1_image_builder.sh
```

## official_secureclaw Build Contents

The builder inserts `images/openclaw/Dockerfile.secureclaw` into the shared OpenClaw Dockerfile and adds:

- `secureclaw` repository source code: `/opt/secureclaw`
- Source installation following `Option C: Plugin from source` in the SecureClaw README:
  - `cd /opt/secureclaw/secureclaw`
  - `npm ci --omit=peer --ignore-scripts`
  - Link the pinned global OpenClaw into `node_modules/openclaw`, so the plugin uses the same runtime and SDK
  - `npm run build`
  - `openclaw plugins install -l .`
- Built-in SecureClaw skill installation: `openclaw secureclaw skill install`

This variant uses the shared `workflow/openclaw.json` without additional configuration overrides.

The plugin source code has been cloned to:

```text
third_party/secureclaw
```

You can also specify another local source directory with an environment variable:

```bash
SECURECLAW_SOURCE_DIR=/path/to/secureclaw \
  bash workflow/workflow_step_1_image_builder.sh
```

## official_clawkeeper Build Contents

The builder inserts `images/openclaw/Dockerfile.clawkeeper` into the shared OpenClaw Dockerfile, applies `clawkeeper.overrides.json` to its configuration copy, and adds:

- `ClawKeeper` plugin source code: `/opt/ClawKeeper/clawkeeper-plugin`
- `plugins.load.paths = ["/opt/ClawKeeper/clawkeeper-plugin"]` in `openclaw.json`

ClawKeeper's `install.sh` runs `npx openclaw plugins install -l .` internally, but OpenClaw's install-time scan blocks installation because the plugin contains `child_process` shell command execution patterns.
This image therefore loads the local plugin path explicitly through `openclaw.json`.

The plugin source code has been cloned to:

```text
third_party/ClawKeeper
```

You can also specify another local source directory with an environment variable:

```bash
CLAWKEEPER_SOURCE_DIR=/path/to/ClawKeeper \
  bash workflow/workflow_step_1_image_builder.sh
```

## hermes / nanoclaw Build Contents

`hermes` and `nanoclaw` wrap third-party agent frameworks so they can be evaluated through the same harness as `official`. Each image ships:

- A custom `/usr/local/bin/openclaw` shim (`images/{type}/openclaw`) that translates AgentCanary's `openclaw agent ...` calls into the framework's native entrypoint — hermes via `run_agent.py`, nanoclaw via the Claude Agent SDK `query` API (`images/nanoclaw/driver.mjs`).
- A `mock-api` sidecar, matching the `official` image.
- The shared model/provider configuration.

`nanoclaw_openai` uses `images/nanoclaw/Dockerfile.openai`, `openclaw_openai`, `driver_claude_openai.mjs`, and `driver_openai.mjs`. Its existing protocol routing and tool permissions are preserved separately from the standard NanoClaw driver within the same directory.

As with every variant, the shared `workflow/openclaw.json` is generated from `config.yaml` by `bash setup.sh` before the build, then copied into each build context.

## Resume Support

Build options and completed images are saved atomically in `{WORK_DIR}/.build_state.json`. Use `--resume WORK_DIR` to reuse those exact options. Completed images are inspected and skipped; failed or missing images are rebuilt. To change framework/version/profile options, use a new workspace. `--prepare-only` never marks images as built.

Legacy `.build_state` shell files remain untouched. Create a new workspace for this builder instead of loading those older state files.
