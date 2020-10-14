
# environment vars
# GOOGLE_PROJECT=${GOOGLE_PROJECT}


.PHONY: all
all: login setup build

login:
	gcloud auth login --no-launch-browser

setup: 
	scripts/setup.sh

build: setup
	packer build packer.json

clean:
	scripts/cleanup.sh