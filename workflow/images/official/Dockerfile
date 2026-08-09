# AgentCanary Runner Image
# Runs OpenClaw agent in isolation for security benchmarks
# docker build -f Dockerfile -t openclaw-official-v{timestamp} --build-arg http_proxy=... .

FROM node:22-bookworm

LABEL org.opencontainers.image.description="AgentCanary benchmark runner with OpenClaw + skills"

# Install system dependencies
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

# Install Python certifi for CA bundle injection
RUN pip3 install certifi --break-system-packages

# Install uv (Python package manager used by AgentCanary)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Install OpenClaw globally
RUN npm install -g openclaw@2026.4.11 --unsafe-perm

# Copy openclaw config to default location (~/.openclaw).
# Skills are NOT baked into the image — they are bind-mounted per task by the
# runner (see scripts/lib_docker.py start(extra_mounts=...) and the resolver
# in scripts/lib_agent.py). The skills/ directory just needs to exist so the
# mock-api entrypoint's glob doesn't error.
RUN mkdir -p /root/.openclaw/skills
COPY docker/openclaw.json /root/.openclaw/openclaw.json

# skill_data is injected per task via docker cp (see _inject_skill_data in
# scripts/lib_agent.py). Only create the parent so the cp target exists.
RUN mkdir -p /tmp/scry/skill_data

# Copy mock_api_data to /tmp/scry/mock_api/data (task-agnostic, stays baked)
RUN mkdir -p /tmp/scry/mock_api/data
COPY docker/mock_api_data/ /tmp/scry/mock_api/data/

# Note: per-skill API mock handlers (api_handlers/*.json) and install
# hooks (skill_hooks/*.sh) are no longer copied at image build time.
# Each skill carries its own mock_assets/ directory (under
# /root/.openclaw/skills/<skill>/mock_assets/), and the mock-api
# entrypoint collects them into /tmp/scry/mock_api/ at container startup.

# Pre-seed any global API handlers. The entrypoint merges per-skill handlers
# on top; the configured web simulation origin is handled separately.
RUN mkdir -p /tmp/scry/mock_api/api_handlers
COPY docker/mock_api_handler[s]/ /tmp/scry/mock_api/api_handlers/

# Copy mock-api
COPY docker/mock-api /opt/mock-api
RUN pip3 install -r /opt/mock-api/requirements.txt --break-system-packages

# Create workspace directory
WORKDIR /workspace

ENTRYPOINT ["/opt/mock-api/entrypoint.sh"]

# Keep container alive for docker exec
CMD ["tail", "-f", "/dev/null"]
