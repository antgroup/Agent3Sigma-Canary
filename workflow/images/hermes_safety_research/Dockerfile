# AgentCanary safety-research runner driving hermes-agent (Nous Research).
# Same outer interface as the OpenClaw image — the `openclaw` shim binary
# translates AgentCanary's CLI calls into hermes invocations.

FROM node:22-bookworm

ENV PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/ \
    PIP_TRUSTED_HOST=mirrors.aliyun.com \
    PIP_DEFAULT_TIMEOUT=120

COPY docker/install-safety-research.sh /usr/local/bin/install-safety-research
COPY docker/wp-cli.phar /usr/local/bin/wp
RUN chmod +x /usr/local/bin/install-safety-research \
    && /usr/local/bin/install-safety-research

# Keep Hermes-only dependencies out of the shared safety layer so Docker can
# reuse that large layer across the Codex, Claude Code, and NanoClaw images.
RUN apt-get -o Acquire::Retries=5 update \
    && apt-get install -y --no-install-recommends python3-venv ripgrep ffmpeg \
    && rm -rf /var/lib/apt/lists/*

COPY docker/wordpress-runtime-smoke.sh /usr/local/bin/wordpress-runtime-smoke
RUN chmod +x /usr/local/bin/wordpress-runtime-smoke

LABEL org.opencontainers.image.description="AgentCanary safety-research runner with hermes-agent + ClawHub skills + document, security, PII, and WordPress tooling"

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

RUN mkdir -p /root/.hermes/skills /root/.openclaw/skills /root/.openclaw/agents

# Selected safety-research skills are available both to mock-api asset
# collection and to Hermes's native user-scope skill discovery.
COPY docker/clawhub_skills/ /root/.openclaw/skills/
RUN cp -a /root/.openclaw/skills/. /root/.hermes/skills/ \
    && ls -1 /root/.hermes/skills > /root/.hermes/skills.bundled

# Install the shim as `openclaw` so AgentCanary sees the same CLI
COPY shim/openclaw /usr/local/bin/openclaw
RUN chmod +x /usr/local/bin/openclaw

# Copy openclaw.json (generated from config.yaml — gives the shim the
# provider/model/api-key table it needs at runtime)
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
