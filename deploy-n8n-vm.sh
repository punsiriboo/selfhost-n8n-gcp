#!/bin/bash

set -e

VOLUME_DIR=$(pwd)/data
CERT_DIR=$(pwd)/certs
FIREWALL_RULE_NAME="allow-http-n8n"
FIREWALL_TAG="n8n-server"

# Check if Docker daemon is running
if ! docker info > /dev/null 2>&1; then
  echo "Docker daemon is not running. Please start it first."
  exit 1
fi

# Generate self-signed certs
mkdir -p "$CERT_DIR"
if [ ! -f "$CERT_DIR/selfsigned.crt" ] || [ ! -f "$CERT_DIR/selfsigned.key" ]; then
  echo "Generating self-signed SSL certificate..."
  openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
    -keyout "$CERT_DIR/selfsigned.key" \
    -out "$CERT_DIR/selfsigned.crt" \
    -subj "/CN=n8n.local"
  echo "Self-signed certificate created successfully."
else
  echo "Certificate already exists. Skipping generation."
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

# Setup GCP firewall rule
if command -v gcloud &> /dev/null; then
  if ! gcloud compute firewall-rules list --format="value(name)" | grep -q "^${FIREWALL_RULE_NAME}$"; then
    echo "Creating firewall rule to allow HTTP (port 80)..."
    gcloud compute firewall-rules create "$FIREWALL_RULE_NAME" \
      --allow tcp:80 \
      --description="Allow HTTP traffic to n8n" \
      --direction=INGRESS \
      --priority=1000 \
      --target-tags="$FIREWALL_TAG" \
      --source-ranges=0.0.0.0/0
  else
    echo "Firewall rule '$FIREWALL_RULE_NAME' already exists."
  fi
else
  echo "gcloud CLI not found. Skipping firewall rule setup."
fi

echo "Starting Docker Compose..."
docker compose --env-file .env up -d

echo ""
echo "n8n is now running at: https://${EXTERNAL_IP} (self-signed cert)"
echo "Postgres data is stored in: $VOLUME_DIR/postgres"