# AgentCanary runner image driving the OpenAI Codex CLI (`codex exec`).
#
# Sibling of workflow/images/claude_code (which drives the Claude Code CLI). A
# Python shim implements the AgentCanary `openclaw agent ...` surface and
# converts `codex exec --json` event JSONL into the minimal AgentCanary
# transcript format.
#
# Two permission regimes are supported, selected at runtime via the
# CODEX_PERMISSION_MODE env var (passed through `docker exec`):
#   - auto-review -> `-s workspace-write` + approval_policy=on-request +
#                    approvals_reviewer=auto_review: Codex runs inside its own
#                    sandbox, and every action that hits the sandbox boundary is
#                    reviewed by the built-in "guardian" reviewer sub-agent
#                    instead of being shown to a human.
#   - yolo        -> `--dangerously-bypass-approvals-and-sandbox`: no sandbox,
#                    no approvals (the analogue of Claude Code bypassPermissions).
#
# IMPORTANT — the container MUST be started with BOTH
#   --security-opt seccomp=unconfined --security-opt apparmor=unconfined
# Codex's bundled `bwrap` sandbox needs an unprivileged user namespace (blocked
# by Docker's default seccomp profile: "bwrap: No permissions to create a new
# namespace") and mount-propagation changes (blocked by the docker-default
# AppArmor profile: "bwrap: Failed to make / slave: Permission denied").
# Without both, every command fails AND auto-review never fires (no sandbox
# boundary => no escalation => no guardian review). See scripts/lib_docker.start(),
# which adds the flags for codex images.

FROM node:22-bookworm

LABEL org.opencontainers.image.description="AgentCanary benchmark runner driving the OpenAI Codex CLI (auto-review / yolo)"

RUN apt-get update && apt-get install -y \
        python3 \
        python3-pip \
        git \
        curl \
        jq \
        iptables \
        ca-certificates \
        openssl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Install the Codex CLI globally. Pin the exact version for reproducibility;
# validate the shim and automatic approval behavior when upgrading.
ARG CODEX_VERSION=0.145.0
RUN npm install -g "@openai/codex@${CODEX_VERSION}" \
    && codex --version | grep -q "${CODEX_VERSION}"

RUN mkdir -p /root/.openclaw/skills /root/.openclaw/agents \
             /root/.codex /root/.agents/skills

# Bake the mock_api TLS cert path into image-level ENV so any `docker exec`'d
# process inherits it — entrypoint.sh's `export` only reaches processes it
# spawns directly. The cert itself is created at runtime by entrypoint.sh.
ENV NODE_EXTRA_CA_CERTS=/tmp/scry/mock_api/ssl/mock-api.crt
# Headless reliability: never auto-update or phone home mid-eval.
ENV CODEX_DISABLE_UPDATE_CHECK=1
ENV CODEX_HOME=/root/.codex
ENV DISABLE_TELEMETRY=1
ENV DO_NOT_TRACK=1

COPY shim/openclaw /usr/local/bin/openclaw
COPY shim/agentcanary_runtime.py /usr/local/bin/agentcanary_runtime.py
RUN chmod +x /usr/local/bin/openclaw

COPY docker/openclaw.json /root/.openclaw/openclaw.json
# ModelInfo template used by the shim to synthesise `model_catalog_json` for
# whatever custom model the run selects. Without a catalog entry the guardian
# falls back to the built-in slug `codex-auto-review`, which a third-party
# endpoint does not serve, causing reviews to fail closed.
COPY docker/model_template.json /opt/codex/model_template.json

# Benchmark skills are bind-mounted per task by the runner into both the
# mock-api collection root and Codex's native discovery root.
RUN mkdir -p /tmp/scry/skill_data /tmp/scry/mock_api/data
COPY docker/mock_api_data/ /tmp/scry/mock_api/data/

RUN mkdir -p /tmp/scry/mock_api/api_handlers
COPY docker/mock_api_handler[s]/ /tmp/scry/mock_api/api_handlers/

COPY docker/mock-api /opt/mock-api
RUN pip3 install -r /opt/mock-api/requirements.txt --break-system-packages

WORKDIR /workspace

ENTRYPOINT ["/opt/mock-api/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
