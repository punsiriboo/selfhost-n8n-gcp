PROJECT_ID := $(shell gcloud config get-value project)
ZONE := asia-southeast1
VM_NAME := n8n-vm


create-vm: ## สร้าง VM พร้อม startup script
	gcloud compute instances create "$(VM_NAME)" \
		--project="$(PROJECT_ID)" \
		--zone="$(ZONE)" \
		--machine-type=e2-micro \
		--image-family=debian-11 \
		--image-project=debian-cloud \
		--boot-disk-size=10GB \
		--tags=n8n-server \
		--scopes=https://www.googleapis.com/auth/cloud-platform \
		--metadata-from-file startup-script=startup.sh \
		--network-tier=STANDARD
		
ssh: ## SSH เข้า VM
	gcloud compute ssh $(VM_NAME) --zone=$(ZONE)

open: ## แสดง External IP เพื่อเปิด n8n UI
	@echo "Browse your n8n UI at:"
	@gcloud compute instances describe $(VM_NAME) --zone=$(ZONE) --format='value(networkInterfaces[0].accessConfigs[0].natIP)' | xargs -I{} echo "http://{}"

delete: ## ลบ VM
	gcloud compute instances delete $(VM_NAME) --zone=$(ZONE) --quiet

.PHONY: list help

## list: แสดงคำสั่งทั้งหมดที่สามารถใช้ได้
list help:
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'