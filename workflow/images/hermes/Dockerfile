# AgentCanary runner image driving hermes-agent (Nous Research).
# Same outer interface as the OpenClaw image — the `openclaw` shim binary
# translates AgentCanary's CLI calls into hermes invocations.

FROM node:22-bookworm

LABEL org.opencontainers.image.description="AgentCanary benchmark runner with hermes-agent + skills + mock-api"

RUN apt-get update && apt-get install -y \
        python3 \
        python3-pip \
        python3-venv \
        git \
        curl \
        jq \
        iptables \
        ripgrep \
        ffmpeg \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# uv for the host python tooling (used by AgentCanary's own scripts elsewhere)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

ARG HERMES_AGENT_REF=9c0807070388c4f612a827230f1314ebbf24e857
RUN git init -q /opt/hermes-agent \
    && git -C /opt/hermes-agent remote add origin https://github.com/NousResearch/hermes-agent.git \
    && git -C /opt/hermes-agent fetch --depth 1 origin "${HERMES_AGENT_REF}" \
    && git -C /opt/hermes-agent checkout --detach FETCH_HEAD

WORKDIR /opt/hermes-agent

# Build a self-contained venv inside the image so we don't pollute system Python.
# `pip install .` walks hermes-agent's pyproject deps; on failure (e.g. an
# optional extra missing a wheel) we still ensure the minimal set the
# AgentCanary shim hits via run_agent.py is present.
RUN python3 -m venv /opt/hermes-agent/.venv \
    && /opt/hermes-agent/.venv/bin/pip install --upgrade pip wheel \
    && (/opt/hermes-agent/.venv/bin/pip install . || true) \
    && /opt/hermes-agent/.venv/bin/pip install \
            'anthropic>=0.39.0' \
            'openai>=1.0.0' \
            fire \
            pyyaml \
            requests \
            httpx \
            python-dotenv \
            prompt_toolkit \
            rich \
            websockets \
            tiktoken \
            jsonschema \
            sqlitedict \
            pydantic

ENV PATH="/opt/hermes-agent/.venv/bin:${PATH}"
ENV HERMES_HOME="/root/.hermes"
ENV HERMES_QUIET="1"

RUN mkdir -p /root/.hermes /root/.openclaw/skills /root/.openclaw/agents

# Install the shim as `openclaw` so AgentCanary sees the same CLI
COPY shim/openclaw /usr/local/bin/openclaw
RUN chmod +x /usr/local/bin/openclaw

# Copy openclaw.json (generated from config.yaml — gives the shim the
# provider/model/api-key table it needs at runtime)
COPY docker/openclaw.json /root/.openclaw/openclaw.json

# Copy skills (agentskills.io format — same as openclaw)
COPY docker/skills/ /root/.openclaw/skills/

# Install skills to where hermes natively looks for them: ~/.hermes/skills/<name>/
# per https://hermes-agent.nousresearch.com/docs/user-guide/features/skills.
# Directory name MUST be the base skill name (no version suffix) — strip
# "-1.0.0" from packaged directory names so hermes' skill_view tool resolves
# them by the `name:` field in SKILL.md.
# Also keep /root/.openclaw/skills/<name>/ (no version) for any code path that
# still expects the openclaw-style location.
ARG SKILL_INSTALL_BUSTER=20260525_v3
RUN mkdir -p /root/.hermes/skills \
    && cd /root/.openclaw/skills \
    && for d in *-*.*.*; do \
         n="${d%-*}"; \
         mkdir -p "/root/.hermes/skills/$n"; \
         cp -rL "$d/." "/root/.hermes/skills/$n/" 2>/dev/null || cp -r "$d/." "/root/.hermes/skills/$n/"; \
       done \
    && for d in *-*.*.*; do \
         n="${d%-*}"; \
         [ -d "$n" ] || ln -s "$d" "$n"; \
       done \
    && ls -la /root/.hermes/skills \
    && ls /root/.hermes/skills > /root/.hermes/skills.bundled

# skill_data + mock_api_data + mock-api (identical to official image)
RUN mkdir -p /tmp/scry/skill_data /tmp/scry/mock_api/data
COPY docker/skill_data/ /tmp/scry/skill_data/
COPY docker/mock_api_data/ /tmp/scry/mock_api/data/

COPY docker/mock-api /opt/mock-api
RUN pip3 install -r /opt/mock-api/requirements.txt --break-system-packages

WORKDIR /workspace

ENTRYPOINT ["/opt/mock-api/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
