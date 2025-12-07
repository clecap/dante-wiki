# Base image with a non-root 'vscode' user already set up
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install Node.js, PHP, Python and common tools
RUN apt-get update && \
  apt-get install -y \
    curl \
    ca-certificates \
    git \
    php-cli \
    php-mbstring \
    php-xml \
    php-curl \
    php-zip \
    composer \
    python3 \
    python3-pip \
    python3-venv \
    build-essential && \
    curl -sSL https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 -o /usr/local/bin/hadolint && \
    chmod +x /usr/local/bin/hadolint && \
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
  apt-get install -y nodejs && \
  apt-get clean && rm -rf /var/lib/apt/lists/*




# Optional: upgrade npm globally
RUN npm install -g npm

# Default workdir matches VS Code project folder
WORKDIR /workspaces/project
