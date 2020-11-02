#!/bin/bash

set -xe

########################################################################
# Cleanup Setup Google Cloud Service Account and Database
########################################################################

# if directory exist delete it
if [[ -d ./cred ]]; then
    rm -rf ./cred
fi

# remove iam project editor role for terraform service account
gcloud projects remove-iam-policy-binding $GOOGLE_PROJECT \
    --member="serviceAccount:terraform@$GOOGLE_PROJECT.iam.gserviceaccount.com" --role='roles/editor'

# remove iam compute instance v1 admin role for packer service account
gcloud projects remove-iam-policy-binding $GOOGLE_PROJECT \
    --member="serviceAccount:packer@$GOOGLE_PROJECT.iam.gserviceaccount.com" --role='roles/compute.instanceAdmin.v1'

# remove iam policy for packer service account
gcloud projects remove-iam-policy-binding $GOOGLE_PROJECT \
    --member="serviceAccount:packer@$GOOGLE_PROJECT.iam.gserviceaccount.com" --role='roles/iam.serviceAccountUser'

# delete packer and terraform service accounts
gcloud iam service-accounts delete "terraform@$GOOGLE_PROJECT.iam.gserviceaccount.com" --quiet
gcloud iam service-accounts delete "packer@$GOOGLE_PROJECT.iam.gserviceaccount.com" --quiet

# enable compute engine api
gcloud services disable compute.googleapis.com

# enable sql-component and sql-admin google apis
gcloud services disable sql-component.googleapis.com
gcloud services disable sqladmin.googleapis.com

# remove the remote-state storage bucket
gsutil rb -f gs://$GOOGLE_PROJECT-remote-state/
