#!/bin/bash

set -xe

######################################################
# Setup Google Cloud Service Account
######################################################

## project name is required to be avaliable via the env.
sudo gcloud config set project $GOOGLE_PROJECT

if [[ ! -d ./cred ]]; then
    mkdir -p ./cred
fi

cd ./cred

# create terraform iam service account
sudo gcloud iam service-accounts create terraform \
    --display-name "Terraform Service Account" \
    --description "Service account to use with Terraform"

sudo gcloud projects add-iam-policy-binding "$GOOGLE_PROJECT" \
    --member serviceAccount:"terraform@$GOOGLE_PROJECT.iam.gserviceaccount.com" \
    --role roles/editor

sudo gcloud iam service-accounts keys create terraform_sa_key.json \
    --iam-account "terraform@$GOOGLE_PROJECT.iam.gserviceaccount.com"

# create packer iam service account
sudo gcloud iam service-accounts create packer \
    --project $GOOGLE_PROJECT \
    --description="Packer Service Account" \
    --display-name="Service account to use with Packer"

sudo gcloud projects add-iam-policy-binding $GOOGLE_PROJECT \
    --member=serviceAccount:"packer@$GOOGLE_PROJECT.iam.gserviceaccount.com" \
    --role=roles/compute.instanceAdmin.v1

sudo gcloud projects add-iam-policy-binding $GOOGLE_PROJECT \
    --member=serviceAccount:"packer@$GOOGLE_PROJECT.iam.gserviceaccount.com" \
    --role=roles/iam.serviceAccountUser

sudo gcloud iam service-accounts keys create packer_sa_key.json \
    --iam-account "packer@$GOOGLE_PROJECT.iam.gserviceaccount.com"

sudo gcloud services enable compute.googleapis.com

sudo gcloud services enable sql-component.googleapis.com

sudo gcloud services enable sqladmin.googleapis.com

sudo gsutil mb -b on -l us-east1 gs://$GOOGLE_PROJECT-remote-state/
