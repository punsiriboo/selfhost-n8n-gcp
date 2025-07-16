#!/bin/bash

echo "Installing Docker and dependencies..."
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl software-properties-common git

if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  usermod -aG docker $USER
fi

DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p "$DOCKER_CONFIG/cli-plugins"
if ! [ -f "$DOCKER_CONFIG/cli-plugins/docker-compose" ]; then
  curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
    -o "$DOCKER_CONFIG/cli-plugins/docker-compose"
  chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"
fi

# Auto-login docker group for future sessions (only affects future ssh logins)
echo "newgrp docker" >> /etc/profile