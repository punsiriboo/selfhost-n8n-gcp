#!/bin/bash

set -e

echo "Installing Docker and dependencies..."
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl software-properties-common git

# Install Docker
if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  usermod -aG docker $(whoami)
fi

# Install Docker Compose Plugin
DOCKER_CONFIG="/root/.docker"
mkdir -p "$DOCKER_CONFIG/cli-plugins"
if [ ! -f "$DOCKER_CONFIG/cli-plugins/docker-compose" ]; then
  curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
    -o "$DOCKER_CONFIG/cli-plugins/docker-compose"
  chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"
fi

# Clone the repo if not exists
REPO="https://github.com/punsiriboo/selfhost-n8n-gcp.git"
cd /root
if [ ! -d selfhost-n8n-gcp ]; then
  git clone "$REPO"
fi

echo "Startup script complete."