# AgentCanary runner image driving nanoclaw's container runtime.
# nanoclaw is a thin wrapper over @anthropic-ai/claude-agent-sdk plus a
# message-bus / container-isolation layer; for benchmarking purposes we
# drive the same SDK directly with nanoclaw's tool allowlist and
# system-prompt configuration (see container/agent-runner/src/providers/claude.ts).

FROM node:22-bookworm

LABEL org.opencontainers.image.description="AgentCanary benchmark runner driving nanoclaw runtime (Claude Agent SDK)"

RUN apt-get update && apt-get install -y \
        python3 \
        python3-pip \
        git \
        curl \
        jq \
        iptables \
        dnsutils \
        ca-certificates \
        openssl \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install certifi --break-system-packages

RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

ARG NANOCLAW_REF=cabc7c0f82ed08a85f763eaa063f162abdc1fa1c
RUN git init -q /opt/nanoclaw \
    && git -C /opt/nanoclaw remote add origin https://github.com/nanocoai/nanoclaw.git \
    && git -C /opt/nanoclaw fetch --depth 1 origin "${NANOCLAW_REF}" \
    && git -C /opt/nanoclaw checkout --detach FETCH_HEAD

# Install the SDK + adjacent packages nanoclaw uses
WORKDIR /opt/nanoclaw-driver
COPY shim/driver.mjs /opt/nanoclaw-driver/driver.mjs
RUN npm init -y \
    && npm install \
        @anthropic-ai/claude-agent-sdk@^0.2 \
        @anthropic-ai/claude-code@^2 \
    && true

RUN mkdir -p /root/.openclaw/skills /root/.openclaw/agents /root/.claude \
    && echo '{"skipWebFetchPreflight": true}' > /root/.claude/settings.json

# Bake the mock_api TLS cert path into image-level ENV so any docker exec'd
# process (driver.mjs, shim subprocesses) inherits it — entrypoint.sh's
# `export` only reaches processes it spawns directly. The cert is created
# at runtime by entrypoint.sh; this just tells Bun/Node where to look.
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
