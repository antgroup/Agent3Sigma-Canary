# AgentCanary safety-research runner driving the Claude Code CLI (`claude`).
#
# Unlike the nanoclaw image (which drives @anthropic-ai/claude-agent-sdk via a
# Node driver), this image drives the *first-party* `claude` command-line tool
# in non-interactive print mode (`claude -p --output-format stream-json`). The
# Python shim translates the AgentCanary `openclaw agent ...` CLI calls into a
# `claude -p` invocation and converts the stream-json event log back into the
# minimal AgentCanary transcript format.
#
# Two permission regimes are supported, selected at runtime via the
# CLAUDE_PERMISSION_MODE env var (passed through `docker exec`):
#   - auto   -> `--permission-mode auto`  (+ CLAUDE_CODE_ENABLE_AUTO_MODE=1):
#               a separate "security monitor" classifier model reviews each
#               risky tool call before it runs.
#   - bypass -> `--permission-mode bypassPermissions` (+ IS_SANDBOX=1 so the
#               root-uid guard is lifted inside this isolated container): no
#               permission checks at all.

FROM node:22-bookworm

ENV PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/ \
    PIP_TRUSTED_HOST=mirrors.aliyun.com \
    PIP_DEFAULT_TIMEOUT=120

COPY docker/install-safety-research.sh /usr/local/bin/install-safety-research
COPY docker/wp-cli.phar /usr/local/bin/wp
RUN chmod +x /usr/local/bin/install-safety-research \
    && /usr/local/bin/install-safety-research

COPY docker/wordpress-runtime-smoke.sh /usr/local/bin/wordpress-runtime-smoke
RUN chmod +x /usr/local/bin/wordpress-runtime-smoke

LABEL org.opencontainers.image.description="AgentCanary safety-research runner with Claude Code + ClawHub skills + document, security, PII, and WordPress tooling"

RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Install the Claude Code CLI globally so `claude` is on PATH.
# Pinned to an EXACT version (no `^` range) for reproducibility — this is the
# version the eval results in docs/claude_code_eval_results_*.md were produced
# with. Bump deliberately, and re-validate, when you want a newer CLI.
ARG CLAUDE_CODE_VERSION=2.1.190
RUN npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
    && claude --version | grep -q "${CLAUDE_CODE_VERSION}"

RUN mkdir -p /root/.openclaw/skills /root/.openclaw/agents /root/.claude/skills

# Selected safety-research skills are available both to mock-api asset
# collection and to Claude Code's native user-scope skill discovery.
COPY docker/clawhub_skills/ /root/.openclaw/skills/
RUN cp -a /root/.openclaw/skills/. /root/.claude/skills/
# Headless settings: skip the claude.ai WebFetch domain preflight (issue #6388)
# which is unreachable from the isolated container.
RUN printf '%s\n' '{"skipWebFetchPreflight": true}' > /root/.claude/settings.json

# Bake the mock_api TLS cert path into image-level ENV so any `docker exec`'d
# process (claude's bundled fetch runtime, shim subprocesses) inherits it —
# entrypoint.sh's `export` only reaches processes it spawns directly. The cert
# is created at runtime by entrypoint.sh; this just tells the runtime where to
# look so WebFetch's http->https auto-upgrade reaches the in-container listener.
ENV NODE_EXTRA_CA_CERTS=/tmp/scry/mock_api/ssl/mock-api.crt
ENV CLAUDE_CODE_CERT_STORE=bundled,system
# Headless reliability: never auto-update / phone home mid-eval.
ENV CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
ENV DISABLE_AUTOUPDATER=1
ENV DISABLE_TELEMETRY=1
ENV DISABLE_ERROR_REPORTING=1
ENV CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1

COPY shim/openclaw /usr/local/bin/openclaw
RUN chmod +x /usr/local/bin/openclaw

COPY docker/openclaw.json /root/.openclaw/openclaw.json

# Benchmark skills are bind-mounted per task by the runner into both the
# mock-api collection root and Claude Code's native discovery root.
RUN mkdir -p /tmp/scry/skill_data /tmp/scry/mock_api/data
COPY docker/mock_api_data/ /tmp/scry/mock_api/data/

RUN mkdir -p /tmp/scry/mock_api/api_handlers
COPY docker/mock_api_handler[s]/ /tmp/scry/mock_api/api_handlers/

COPY docker/mock-api /opt/mock-api
RUN pip3 install -r /opt/mock-api/requirements.txt --break-system-packages

WORKDIR /workspace

ENTRYPOINT ["/opt/mock-api/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
