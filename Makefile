PROJECT_ID := $(shell gcloud config get-value project)
ZONE := us-central1-a
VM_NAME := n8n-vm
REPO := https://github.com/punsiriboo/selfhost-n8n-gcp.git

create-vm:
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

ssh:
	gcloud compute ssh $(VM_NAME) --zone=$(ZONE)

deploy:
	gcloud compute ssh $(VM_NAME) --zone=$(ZONE) --command="bash -c '\
		if [ ! -d selfhost-n8n-gcp ]; then \
			git clone $(REPO); \
		fi && \
		cd selfhost-n8n-gcp && \
		chmod +x deploy-n8n-vm.sh && \
		./deploy-n8n-vm.sh'"

open:
	@echo "🔗 Browse your n8n UI at:"
	@gcloud compute instances describe $(VM_NAME) --zone=$(ZONE) --format='value(networkInterfaces[0].accessConfigs[0].natIP)' | xargs -I{} echo "http://{}"

delete:
	gcloud compute instances delete $(VM_NAME) --zone=$(ZONE) --quiet