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
    && rm -rf /var/lib/apt/lists/*

# Install uv (Python package manager used by AgentCanary)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Install OpenClaw globally
RUN npm install -g openclaw@2026.4.11 --unsafe-perm

# Copy openclaw config and skills to default location (~/.openclaw)
RUN mkdir -p /root/.openclaw/skills
COPY docker/openclaw.json /root/.openclaw/openclaw.json
COPY docker/skills/ /root/.openclaw/skills/

# Copy skill_data to /tmp/scry/skill_data
RUN mkdir -p /tmp/scry/skill_data
COPY docker/skill_data/ /tmp/scry/skill_data/

# Copy mock_api_data to /tmp/scry/mock_api/data
RUN mkdir -p /tmp/scry/mock_api/data
COPY docker/mock_api_data/ /tmp/scry/mock_api/data/

# Copy mock-api
COPY docker/mock-api /opt/mock-api
RUN pip3 install -r /opt/mock-api/requirements.txt --break-system-packages

# Create workspace directory
WORKDIR /workspace

ENTRYPOINT ["/opt/mock-api/entrypoint.sh"]

# Keep container alive for docker exec
CMD ["tail", "-f", "/dev/null"]