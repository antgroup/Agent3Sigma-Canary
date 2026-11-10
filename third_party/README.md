# Vendored OpenClaw plugins

These source trees were moved unchanged from the former `workflow/images/official_*` directories. Each retains its upstream documentation and license files.

| Directory | Upstream | Local source override |
| --- | --- | --- |
| `openclaw-shield/` | https://github.com/knostic/openclaw-shield | `OPENCLAW_SHIELD_SOURCE_DIR` |
| `secureclaw/` | https://github.com/adversa-ai/secureclaw | `SECURECLAW_SOURCE_DIR` |
| `ClawKeeper/` | https://github.com/SafeAI-Lab-X/ClawKeeper | `CLAWKEEPER_SOURCE_DIR` |

`workflow/build_images.py` copies the selected plugin into its build context and combines its build fragment with the shared OpenClaw Dockerfile. Source overrides accept a local checkout of the corresponding upstream repository. Context preparation does not download plugin source.
