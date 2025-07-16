#!/bin/bash

set -e

REPO_URL="https://github.com/YOUR_USERNAME/SELFHOST-N8N-GCP.git"
REPO_DIR="selfhost-n8n-gcp"
VOLUME_DIR=$(pwd)/data

# Install dependencies
echo "Installing Docker and dependencies..."
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common git

# Install Docker
if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  sudo usermod -aG docker $USER
fi

# Install Docker Compose CLI plugin
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
if ! [ -f "$DOCKER_CONFIG/cli-plugins/docker-compose" ]; then
  curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
    -o $DOCKER_CONFIG/cli-plugins/docker-compose
  chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
fi

# Clone repo if not exists
if [ ! -d "$REPO_DIR" ]; then
  echo "Cloning repository..."
  git clone $REPO_URL $REPO_DIR
fi
cd $REPO_DIR

# Create .env from example if not exists
if [ ! -f .env ]; then
  echo "Creating .env from .env.example"
  cp .env.example .env
fi

# Read EXTERNAL_IP if not set
EXTERNAL_IP=$(grep ^EXTERNAL_IP= .env | cut -d '=' -f2)
if [ -z "$EXTERNAL_IP" ]; then
  read -p "Enter your VM's external IP: " INPUT_IP
  sed -i "s|^EXTERNAL_IP=.*|EXTERNAL_IP=${INPUT_IP}|" .env
  echo "EXTERNAL_IP=${INPUT_IP}" >> .env
  EXTERNAL_IP=$INPUT_IP
else
  echo "Using existing EXTERNAL_IP from .env: $EXTERNAL_IP"
fi

# Ensure data directory exists
mkdir -p "$VOLUME_DIR/postgres"

# Replace volume path in docker-compose.yml if not already
if ! grep -q "$VOLUME_DIR/postgres" docker-compose.yml; then
  sed -i "s|postgres_data:/var/lib/postgresql/data|${VOLUME_DIR}/postgres:/var/lib/postgresql/data|" docker-compose.yml
fi

# Start containers
echo "Running Docker Compose..."
docker compose up -d

echo ""
echo "n8n is running at: http://${EXTERNAL_IP}"
echo "Postgres data is persisted at: $VOLUME_DIR/postgres"
