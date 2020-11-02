#!/bin/bash

set -xe

######################################################
# Setup Google Cloud Service Account
######################################################

## project name is required to be avaliable via the env.
gcloud config set project $GOOGLE_PROJECT

# check if the directory doesn't exist
if [[ ! -d ./cred ]]; then
    # create directory
    mkdir -p ./cred
fi

# change  to cred directory
cd ./cred

# create terraform iam service account
gcloud iam service-accounts create terraform \
    --display-name "Terraform Service Account" \
    --description "Service account to use with Terraform"

# policy for project editor role
gcloud projects add-iam-policy-binding "$GOOGLE_PROJECT" \
    --member serviceAccount:"terraform@$GOOGLE_PROJECT.iam.gserviceaccount.com" \
    --role roles/editor

# create service account keyfiles
gcloud iam service-accounts keys create terraform_sa_key.json \
    --iam-account "terraform@$GOOGLE_PROJECT.iam.gserviceaccount.com"

# create packer iam service account
gcloud iam service-accounts create packer \
    --project $GOOGLE_PROJECT \
    --description="Packer Service Account" \
    --display-name="Service account to use with Packer"

# policy for compute instance v1 admin
gcloud projects add-iam-policy-binding $GOOGLE_PROJECT \
    --member=serviceAccount:"packer@$GOOGLE_PROJECT.iam.gserviceaccount.com" \
    --role=roles/compute.instanceAdmin.v1

# policy for service account
gcloud projects add-iam-policy-binding $GOOGLE_PROJECT \
    --member=serviceAccount:"packer@$GOOGLE_PROJECT.iam.gserviceaccount.com" \
    --role=roles/iam.serviceAccountUser

# create service account keyfiles
gcloud iam service-accounts keys create packer_sa_key.json \
    --iam-account "packer@$GOOGLE_PROJECT.iam.gserviceaccount.com"

# enable compute engine api
gcloud services enable compute.googleapis.com

# enable sql-component and sql-admin google apis
gcloud services enable sql-component.googleapis.com
gcloud services enable sqladmin.googleapis.com

# create storage bucket for remote state
gsutil mb -b on -l us-central1 gs://$GOOGLE_PROJECT-remote-state/
