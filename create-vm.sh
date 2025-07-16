export PROJECT_ID=$(gcloud config get-value project)
export ZONE=us-central1-a
export VM_NAME=n8n-vm

gcloud compute instances create "${VM_NAME}" \
    --project="${PROJECT_ID}" \
    --zone="${ZONE}" \
    --machine-type=e2-micro \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --boot-disk-size=10GB \
    --tags=n8n-server \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --metadata=startup-script='#! /bin/bash
        sudo apt-get update
        sudo apt-get install -y git' \
    --network-tier=STANDARD
