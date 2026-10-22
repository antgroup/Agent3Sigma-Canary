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
        dnsutils \
        openssl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install certifi --break-system-packages

RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Pull nanoclaw source for reference. Driver code is in workflow/images/.
# Pinned to the same validated upstream commit as the nanoclaw image
# (committed 2026-05-23) for reproducible builds. Override:
#   --build-arg NANOCLAW_REF=<sha>
ARG NANOCLAW_REF=cabc7c0f82ed08a85f763eaa063f162abdc1fa1c
RUN git init -q /opt/nanoclaw \
    && git -C /opt/nanoclaw remote add origin https://github.com/nanocoai/nanoclaw.git \
    && git -C /opt/nanoclaw fetch --depth 1 origin "${NANOCLAW_REF}" \
    && git -C /opt/nanoclaw checkout --detach FETCH_HEAD

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

RUN mkdir -p /root/.openclaw/skills /root/.openclaw/agents /root/.claude \
    && echo '{"skipWebFetchPreflight": true}' > /root/.claude/settings.json

# The Anthropic/Claude SDK path can upgrade web fetches to HTTPS. The
# entrypoint creates this CA file before the shim runs.
ENV NODE_EXTRA_CA_CERTS=/tmp/scry/mock_api/ssl/mock-api.crt
ENV CLAUDE_CODE_CERT_STORE=bundled,system
# Avoid optional Anthropic control-plane requests when using a custom provider.
# The benchmark's egress policy intentionally permits only configured endpoints.
ENV CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

COPY shim/openclaw /usr/local/bin/openclaw
RUN chmod +x /usr/local/bin/openclaw

COPY docker/openclaw.json /root/.openclaw/openclaw.json

# Skills and skill_data are injected per task by the runner.
RUN mkdir -p /tmp/scry/skill_data /tmp/scry/mock_api/data
COPY docker/mock_api_data/ /tmp/scry/mock_api/data/
RUN mkdir -p /tmp/scry/mock_api/api_handlers
COPY docker/mock_api_handler[s]/ /tmp/scry/mock_api/api_handlers/

COPY docker/mock-api /opt/mock-api
RUN pip3 install -r /opt/mock-api/requirements.txt --break-system-packages

WORKDIR /workspace

ENTRYPOINT ["/opt/mock-api/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
