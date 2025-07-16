#!/bin/bash

set -e


REPO_DIR="selfhost-n8n-gcp"
VOLUME_DIR=$(pwd)/data
FIREWALL_RULE_NAME="allow-http-n8n"
FIREWALL_TAG="n8n-server"

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


# Create .env from example if not exists
if [ ! -f .env ]; then
  echo "Creating .env from .env.example"
  cp .env.example .env
fi

# Read or prompt for EXTERNAL_IP
EXTERNAL_IP=$(grep ^EXTERNAL_IP= .env | cut -d '=' -f2)
if [ -z "$EXTERNAL_IP" ]; then
  read -p "Enter your VM's external IP: " INPUT_IP
  sed -i "s|^EXTERNAL_IP=.*|EXTERNAL_IP=${INPUT_IP}|" .env || echo "EXTERNAL_IP=${INPUT_IP}" >> .env
  EXTERNAL_IP=$INPUT_IP
else
  echo "Using existing EXTERNAL_IP from .env: $EXTERNAL_IP"
fi

# Ensure data directory exists
mkdir -p "$VOLUME_DIR/postgres"

# Replace postgres volume path if not already
if ! grep -q "$VOLUME_DIR/postgres" docker-compose.yml; then
  sed -i "s|postgres_data:/var/lib/postgresql/data|${VOLUME_DIR}/postgres:/var/lib/postgresql/data|" docker-compose.yml
fi

# Setup GCP firewall (requires gcloud CLI and permission)
if command -v gcloud &> /dev/null; then
  if ! gcloud compute firewall-rules list --format="value(name)" | grep -q "^${FIREWALL_RULE_NAME}$"; then
    echo "Creating firewall rule to allow HTTP (port 80)..."
    gcloud compute firewall-rules create $FIREWALL_RULE_NAME \
      --allow tcp:80 \
      --description="Allow HTTP traffic to n8n" \
      --direction=INGRESS \
      --priority=1000 \
      --target-tags=$FIREWALL_TAG \
      --source-ranges=0.0.0.0/0
  else
    echo "Firewall rule '$FIREWALL_RULE_NAME' already exists."
  fi
else
  echo "gcloud CLI not found. Skipping firewall rule setup."
fi

echo "Running Docker Compose..."
docker compose up -d

echo ""
echo "n8n is now running at: http://${EXTERNAL_IP}"
echo "Postgres data is persisted at: $VOLUME_DIR/postgres"
