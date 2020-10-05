
# environment vars
# GOOGLE_PROJECT=${GOOGLE_PROJECT}


.PHONY: all
all: login build

login:
	gcloud auth login --no-launch-browser

# setup: 
# 	sudo ./setup_sa.sh

build:
	packer build packer.json