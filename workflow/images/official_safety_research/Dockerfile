# AgentCanary Safety Research Runner Image
# Runs OpenClaw with the official benchmark stack plus LibreOffice, ClawHub
# local skills, OpenSSH, and WordPress tooling.
# docker build -f Dockerfile -t openclaw-official_safety_research-v{timestamp} --build-arg http_proxy=... .

FROM node:22-bookworm

LABEL org.opencontainers.image.description="AgentCanary benchmark runner with OpenClaw + ClawHub local skills + LibreOffice + OpenSSH + Python research packages"

# Install system dependencies.
RUN sed -i \
        -e 's|http://deb.debian.org/debian-security|https://mirrors.aliyun.com/debian-security|g' \
        -e 's|http://deb.debian.org/debian|https://mirrors.aliyun.com/debian|g' \
        /etc/apt/sources.list.d/debian.sources && \
    apt-get -o Acquire::ForceIPv4=true \
        -o Acquire::Retries=5 \
        -o Acquire::http::Timeout=30 \
        -o Acquire::https::Timeout=30 \
        -o Acquire::http::Pipeline-Depth=0 \
        update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    git \
    openssh-server \
    rsync \
    curl \
    jq \
    iptables \
    dnsutils \
    openssl \
    ca-certificates \
    docker.io \
    docker-compose \
    libreoffice \
    pandoc \
    gnucash \
    python3-gnucash \
    cron \
    at \
    nmap \
    libxml2-utils \
    hledger \
    restic \
    tesseract-ocr \
    tesseract-ocr-eng \
    tesseract-ocr-chi-sim \
    weasyprint \
    fonts-noto-cjk \
    fonts-liberation \
    fontconfig \
    && fc-cache -f \
    && rm -rf /var/lib/apt/lists/*

ENV PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/ \
    PIP_TRUSTED_HOST=mirrors.aliyun.com \
    PIP_DEFAULT_TIMEOUT=120

# Install Python packages for CA bundle injection and research notebooks/plots.
RUN pip3 install --no-cache-dir \
    certifi \
    matplotlib \
    jupyter \
    --break-system-packages

# Presidio PII skill uses localhost Presidio services; install the Python
# packages so interactive sessions can run or debug the analyzer/anonymizer
# stack without downloading Python wheels at runtime.
RUN pip3 install --no-cache-dir \
    presidio-analyzer \
    presidio-anonymizer \
    --break-system-packages

# Install uv (Python package manager used by AgentCanary).
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# Install OpenClaw globally.
RUN npm config set registry https://registry.npmmirror.com
RUN npm install -g openclaw@2026.4.11 --unsafe-perm --ignore-scripts

LABEL org.opencontainers.image.description="AgentCanary benchmark runner with OpenClaw + ClawHub local skills + LibreOffice + OpenSSH + Python research packages + WordPress tooling"

# Install WordPress runtime tooling for safety-research sessions. WP-CLI handles
# real WordPress operations, while WordPress Playground provides disposable
# SQLite-backed environments without requiring a long-running database service.
RUN apt-get -o Acquire::ForceIPv4=true \
        -o Acquire::Retries=5 \
        -o Acquire::http::Timeout=30 \
        -o Acquire::https::Timeout=30 \
        -o Acquire::http::Pipeline-Depth=0 \
        update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    unzip \
    default-mysql-client \
    php-cli \
    php-curl \
    php-gd \
    php-mbstring \
    php-mysql \
    php-sqlite3 \
    php-xml \
    php-zip \
    && rm -rf /var/lib/apt/lists/*
COPY docker/wp-cli.phar /usr/local/bin/wp
RUN chmod +x /usr/local/bin/wp \
    && wp --allow-root --info
RUN npm install -g @wp-playground/cli@3.1.44 --unsafe-perm \
    && wp-playground-cli --version

COPY docker/wordpress-runtime-smoke.sh /usr/local/bin/wordpress-runtime-smoke
RUN chmod +x /usr/local/bin/wordpress-runtime-smoke

# Copy openclaw config to default location (~/.openclaw).
# Benchmark skills are bind-mounted per task by the runner. Selected local
# ClawHub skills are baked in for interactive safety-research sessions.
RUN mkdir -p /root/.openclaw/skills
COPY docker/openclaw.json /root/.openclaw/openclaw.json
COPY docker/clawhub_skills/ /root/.openclaw/skills/

# skill_data is injected per task via docker cp. Only create the parent so the
# cp target exists.
RUN mkdir -p /tmp/scry/skill_data

# Copy mock_api_data to /tmp/scry/mock_api/data (task-agnostic, stays baked).
RUN mkdir -p /tmp/scry/mock_api/data
COPY docker/mock_api_data/ /tmp/scry/mock_api/data/

# Pre-seed global api_handlers (domains not tied to any skill, e.g. openblog.com).
# The entrypoint's collect_skill_mock_assets merges per-skill handlers on top.
RUN mkdir -p /tmp/scry/mock_api/api_handlers
COPY docker/mock_api_handler[s]/ /tmp/scry/mock_api/api_handlers/

# Copy mock-api.
COPY docker/mock-api /opt/mock-api
RUN pip3 install -r /opt/mock-api/requirements.txt --break-system-packages

# Additional Python package for safety-research sessions. opendlp declares
# legacy pinned dependencies that do not resolve cleanly on Python 3.11, so keep
# the install compatible with this base image and avoid forcing those old pins.
RUN pip3 install --no-cache-dir \
    pandas \
    IPy \
    tldextract \
    --break-system-packages \
    && pip3 install --no-cache-dir --no-deps \
    opendlp \
    --break-system-packages

# Create workspace directory.
WORKDIR /workspace

ENTRYPOINT ["/opt/mock-api/entrypoint.sh"]

# Keep container alive for docker exec.
CMD ["tail", "-f", "/dev/null"]
