
# environment vars
# GOOGLE_PROJECT=${GOOGLE_PROJECT}


.PHONY: all
all: login setup build

gcloud-auth:
	gcloud auth login --no-launch-browser

setup: 
	scripts/setup.sh

packer-fix: 
	packer fix packer/image.pkr.hcl

packer-validate: 
	packer validate packer/image.pkr.hcl

packer-build: 
	packer build packer/image.pkr.hcl

terraform-fmt:
	cd terraform/staging/
	terraform fmt

terraform-plan:
	cd terraform/staging/
	terraform plan

terraform-apply:
	cd terraform/staging/
	terraform apply --auto-approve

clean:
	scripts/cleanup.sh
