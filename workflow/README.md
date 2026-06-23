# AgentCanary Workflow

`workflow/` is responsible only for building AgentCanary Docker base images.

## Image Roles

| Image Type | Tag Format | Description |
|------------|------------|-------------|
| `official` | `openclaw-official-v{timestamp}` | Native OpenClaw + custom skills + mock-api server |
| `offical_shield` | `openclaw-offical_shield-v{timestamp}` | `official` + openclaw-shield security plugin |
| `offical_secureclaw` | `openclaw-offical_secureclaw-v{timestamp}` | `official` + SecureClaw security plugin |
| `offical_clawkeeper` | `openclaw-offical_clawkeeper-v{timestamp}` | `official` + ClawKeeper security plugin |
| `hermes` | `openclaw-hermes-v{timestamp}` | hermes-agent (Nous Research) framework wrapped behind an `openclaw` shim + mock-api server |
| `nanoclaw` | `openclaw-nanoclaw-v{timestamp}` | nanoclaw runtime (Claude Agent SDK) wrapped behind an `openclaw` shim + mock-api server |

The `offical_*` variants extend `official` by adding different security plugins. The `hermes` and `nanoclaw` variants instead wrap third-party agent frameworks behind an `openclaw` shim so they can be evaluated through the same harness.

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
    ├── offical_shield/
    │   ├── Dockerfile
    │   ├── openclaw.json
    │   └── prepare.sh
    ├── offical_secureclaw/
    │   ├── secureclaw/
    │   ├── Dockerfile
    │   ├── openclaw.json
    │   └── prepare.sh
    ├── offical_clawkeeper/
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
- `_skills_repository/skill_dest/skills`
- `assets/skill_data`
- `assets/mock_api/data`
- `images/official/mock-api`

`images/official/Dockerfile` installs and configures:

- `openclaw@2026.4.11`
- Custom skills: `/root/.openclaw/skills`
- mock-api server: `/opt/mock-api`
- mock-api data: `/tmp/scry/mock_api/data`
- Skill data: `/tmp/scry/skill_data`

## offical_shield Build Contents

`images/offical_shield/prepare.sh` first reuses `images/official/prepare.sh` to generate a complete official build context, then adds:

- `openclaw-shield` source code: `/opt/openclaw-shield`
- Dockerfile installation step: `openclaw plugins install /opt/openclaw-shield`
- `tools.profile = "full"` in `openclaw.json`, so `knostic_shield` is included in the agent's actual tool list

`offical_shield/openclaw.json` remains consistent with `official/openclaw.json` and does not manually add plugin configuration.

The plugin source code must be cloned in advance. The build does not access GitHub.
The default source location is:

```text
workflow/images/offical_shield/openclaw-shield
```

You can also specify another local source directory with an environment variable:

```bash
OPENCLAW_SHIELD_SOURCE_DIR=/path/to/openclaw-shield \
  bash workflow/workflow_step_1_image_builder.sh
```

## offical_secureclaw Build Contents

`images/offical_secureclaw/prepare.sh` first reuses `images/official/prepare.sh` to generate a complete official build context, then adds:

- `secureclaw` repository source code: `/opt/secureclaw`
- Source installation following `Option C: Plugin from source` in the SecureClaw README:
  - `cd /opt/secureclaw/secureclaw`
  - `npm install`
  - `npm run build`
  - `npx openclaw plugins install -l .`
- Built-in SecureClaw skill installation: `npx openclaw secureclaw skill install`

`offical_secureclaw/openclaw.json` remains consistent with `official/openclaw.json` and does not manually add plugin configuration.

The plugin source code has been cloned to:

```text
workflow/images/offical_secureclaw/secureclaw
```

You can also specify another local source directory with an environment variable:

```bash
SECURECLAW_SOURCE_DIR=/path/to/secureclaw \
  bash workflow/workflow_step_1_image_builder.sh
```

## offical_clawkeeper Build Contents

`images/offical_clawkeeper/prepare.sh` first reuses `images/official/prepare.sh` to generate a complete official build context, then adds:

- `ClawKeeper` plugin source code: `/opt/ClawKeeper/clawkeeper-plugin`
- `plugins.load.paths = ["/opt/ClawKeeper/clawkeeper-plugin"]` in `openclaw.json`

ClawKeeper's `install.sh` runs `npx openclaw plugins install -l .` internally, but OpenClaw's install-time scan blocks installation because the plugin contains `child_process` shell command execution patterns.
This image therefore loads the local plugin path explicitly through `openclaw.json`.

The plugin source code has been cloned to:

```text
workflow/images/offical_clawkeeper/ClawKeeper
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

The build script supports resuming interrupted builds:

- State is saved in `{WORK_DIR}/.build_state`
- When rerun after interruption, the script detects existing workspaces
- The user can continue, overwrite the existing workspace, or create a new workspace
