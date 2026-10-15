#!/bin/bash
set -euo pipefail

# Shared package layer for every *_safety_research agent image. Optional
# arguments are extra apt packages required by the underlying agent runtime
# (for example python3-venv, ripgrep, and ffmpeg for Hermes).

apt-get -o Acquire::ForceIPv4=true \
    -o Acquire::Retries=5 \
    -o Acquire::http::Timeout=30 \
    -o Acquire::https::Timeout=30 \
    -o Acquire::http::Pipeline-Depth=0 \
    update

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
    "$@"

fc-cache -f
rm -rf /var/lib/apt/lists/*

/usr/bin/python3 -m pip install --no-cache-dir \
    certifi \
    matplotlib \
    jupyter \
    presidio-analyzer \
    presidio-anonymizer \
    pandas \
    IPy \
    tldextract \
    --break-system-packages

# opendlp's legacy pinned dependency set does not resolve on the base image's
# Python version. The compatible direct dependencies are installed above.
/usr/bin/python3 -m pip install --no-cache-dir --no-deps opendlp --break-system-packages

curl -fsSL --retry 3 https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp
chmod +x /usr/local/bin/wp
wp --allow-root --info

npm install -g @wp-playground/cli@3.1.44 --unsafe-perm
wp-playground-cli --version

install -m 755 /opt/agentcanary-research/wordpress-runtime-smoke.sh /usr/local/bin/wordpress-runtime-smoke
