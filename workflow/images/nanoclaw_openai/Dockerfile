# AgentCanary runner image driving nanoclaw's runtime with OpenAI-format models,
# routed through opencode (nanoclaw's official /add-opencode skill path).
#
# Anthropic-shaped models still go through @anthropic-ai/claude-agent-sdk
# (driver.mjs). OpenAI-compatible models go through opencode (driver_openai.mjs),
# which spawns `opencode serve` locally and proxies via @opencode-ai/sdk.

FROM node:22-bookworm

LABEL org.opencontainers.image.description="AgentCanary nanoclaw runner with OpenAI support via opencode"

RUN apt-get update && apt-get install -y \
        python3 \
        python3-pip \
        git \
        curl \
        jq \
        iptables \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Pull nanoclaw source for reference. Driver code is in workflow/images/.
RUN git clone --depth 1 https://github.com/nanocoai/nanoclaw.git /opt/nanoclaw

# Install opencode CLI globally (the @opencode-ai/cli npm package is named
# `opencode-ai`) plus the claude-code SDK for the anthropic path.
RUN npm install -g opencode-ai@latest @anthropic-ai/claude-code@^2 \
    || npm install -g opencode-ai@latest

# Driver workspace with both drivers + their npm deps
WORKDIR /opt/nanoclaw-driver
COPY shim/driver.mjs        /opt/nanoclaw-driver/driver.mjs
COPY shim/driver_openai.mjs /opt/nanoclaw-driver/driver_openai.mjs
RUN npm init -y \
    && npm install \
        @anthropic-ai/claude-agent-sdk@^0.2 \
        @anthropic-ai/claude-code@^2 \
        @opencode-ai/sdk@^1.4 \
    && true

RUN mkdir -p /root/.openclaw/skills /root/.openclaw/agents /root/.claude/skills \
    && echo '{"skipWebFetchPreflight": true}' > /root/.claude/settings.json

COPY shim/openclaw /usr/local/bin/openclaw
RUN chmod +x /usr/local/bin/openclaw

COPY docker/openclaw.json /root/.openclaw/openclaw.json
COPY docker/skills/ /root/.openclaw/skills/

# Anthropic-API path of this image uses driver.mjs which goes through Claude
# Agent SDK — install skills at ~/.claude/skills/<name>/ to match SDK
# discovery rules. Strip the -1.0.0 version suffix from packaged dirs so
# directory names match the `name:` field in SKILL.md.
# OpenAI path of this image (driver_openai.mjs) goes through opencode, which
# does not have a native agentskills.io concept — agent will need to invoke
# the scripts via Bash with absolute paths under /root/.openclaw/skills/<name>/
# (kept as symlinks here for that workflow too).
ARG SKILL_INSTALL_BUSTER=20260525_v3
RUN cd /root/.openclaw/skills \
    && for d in *-*.*.*; do \
         n="${d%-*}"; \
         mkdir -p "/root/.claude/skills/$n"; \
         cp -rL "$d/." "/root/.claude/skills/$n/" 2>/dev/null || cp -r "$d/." "/root/.claude/skills/$n/"; \
         [ -d "$n" ] || ln -s "$d" "$n"; \
       done \
    && ls -la /root/.claude/skills

RUN mkdir -p /tmp/scry/skill_data /tmp/scry/mock_api/data
COPY docker/skill_data/ /tmp/scry/skill_data/
COPY docker/mock_api_data/ /tmp/scry/mock_api/data/

COPY docker/mock-api /opt/mock-api
RUN pip3 install -r /opt/mock-api/requirements.txt --break-system-packages

WORKDIR /workspace

ENTRYPOINT ["/opt/mock-api/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
