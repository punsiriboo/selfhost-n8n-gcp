# Self-host n8n on GCP VM with Docker

![n8n GCP Setup](assets/title.png)

Deploy [n8n](https://n8n.io) บน Google Cloud VM ด้วย Docker และ Docker Compose พร้อมใช้งานในไม่กี่นาที  
ติดตั้งพร้อม PostgreSQL และรองรับ HTTPS แบบ self-signed certificate

---

## 🚀 วิธีติดตั้งแบบรวดเร็ว

1. Go to Google Cloud Console and create compute engine to host N8N server

```
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
```

```
git clone https://github.com/your-username/selfhost-n8n-gcp.git
cd selfhost-n8n-gcp
```