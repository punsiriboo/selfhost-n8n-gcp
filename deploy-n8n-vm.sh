#!/bin/bash

set -e

VOLUME_DIR=$(pwd)/data
FIREWALL_TAG="n8n-server"
VM_NAME="n8n-vm"
ZONE="us-central1-a"

# Generate ACME cert file
mkdir -p ./letsencrypt
touch ./letsencrypt/acme.json
chmod 600 ./letsencrypt/acme.json

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

# Setup GCP firewall rules and VM tags
if command -v gcloud &> /dev/null; then

  # Add tags to VM
  echo "Adding tags to VM: $VM_NAME"
  gcloud compute instances add-tags "$VM_NAME" \
    --tags="$FIREWALL_TAG,http-server,https-server" \
    --zone="$ZONE"

  # Create allow-http if not exists
  if ! gcloud compute firewall-rules list --format="value(name)" | grep -q "^allow-http$"; then
    echo "Creating firewall rule 'allow-http'..."
    gcloud compute firewall-rules create allow-http \
      --allow tcp:80 \
      --target-tags="$FIREWALL_TAG" \
      --description="Allow HTTP traffic" \
      --direction=INGRESS \
      --priority=1000 \
      --network=default
  else
    echo "Firewall rule 'allow-http' already exists."
  fi

  # Create allow-https if not exists
  if ! gcloud compute firewall-rules list --format="value(name)" | grep -q "^allow-https$"; then
    echo "Creating firewall rule 'allow-https'..."
    gcloud compute firewall-rules create allow-https \
      --allow tcp:443 \
      --target-tags="$FIREWALL_TAG" \
      --description="Allow HTTPS traffic" \
      --direction=INGRESS \
      --priority=1000 \
      --network=default
  else
    echo "Firewall rule 'allow-https' already exists."
  fi

else
  echo "gcloud CLI not found. Skipping firewall and VM tag setup."
fi

echo "Starting Docker Compose..."
docker compose up -d

echo ""
echo "n8n is now running at: https://${EXTERNAL_IP} (self-signed cert)"
echo "Postgres data is stored in: $VOLUME_DIR/postgres"