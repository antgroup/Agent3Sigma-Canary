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
        ca-certificates \
        openssl \
    && rm -rf /var/lib/apt/lists/*

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
ENV NODE_EXTRA_CA_CERTS=/opt/mock-api/tls/server.pem
ENV CLAUDE_CODE_CERT_STORE=bundled,system

COPY shim/openclaw /usr/local/bin/openclaw
RUN chmod +x /usr/local/bin/openclaw

COPY docker/openclaw.json /root/.openclaw/openclaw.json

# Install skills to where Claude Agent SDK natively looks for them
# (~/.claude/skills/<name>/SKILL.md per
# https://code.claude.com/docs/en/agent-sdk/skills). The driver passes
# settingSources:["user","project"] so this user-level location is discovered.
# Skill name (directory) MUST match the `name:` field in SKILL.md frontmatter
# — strip the version suffix from the source packaged dirs (email-1.0.0 → email).
RUN mkdir -p /root/.claude/skills /root/.openclaw/skills
COPY docker/skills/ /root/.openclaw/skills/
ARG SKILL_INSTALL_BUSTER=20260525_v3
RUN cd /root/.openclaw/skills \
    && for d in *-*.*.*; do \
         n="${d%-*}"; \
         mkdir -p "/root/.claude/skills/$n"; \
         cp -rL "$d/." "/root/.claude/skills/$n/" 2>/dev/null || cp -r "$d/." "/root/.claude/skills/$n/"; \
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
