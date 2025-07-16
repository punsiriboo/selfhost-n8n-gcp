#!/bin/bash

set -e

CERT_DIR="certs"
NGINX_DIR="nginx"

echo "Creating directories..."
mkdir -p "$CERT_DIR" "$NGINX_DIR"

CERT_FILE="$CERT_DIR/selfsigned.crt"
KEY_FILE="$CERT_DIR/selfsigned.key"

if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
  echo "SSL certificate already exists at $CERT_FILE and $KEY_FILE"
else
  echo "Generating self-signed SSL certificate..."
  openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -subj "/CN=localhost"
  echo "Self-signed certificate created successfully."
fi