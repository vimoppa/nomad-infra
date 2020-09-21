# nomad-infra

## Intro

Deploying [Nomad](https://www.nomadproject.io/) cluster to Google Cloud Platform using [packer](https://www.packer.io/)

This repo primary contains instructions to setting up a Google Cloud Platform project and building a Golden Image using Packer.

Includes:

* Install Hashicorp Tools (Nomad, Consul, Vault, Terraform, Packer).
* Install the GCP SDK CLI Tools, if you're not using the Cloud Shell.
* Creating a new GCP Project, along with a Terraform Service Account.
* Building a golden image using Packer.
* [Deployment a cluster with terraform](https://github.com/ucontex/terraform).

## Install HashiCorp Tools

* [Nomad](https://www.nomadproject.io/downloads)

* [Consul](https://www.consul.io/downloads)

* [Vault](https://www.vaultproject.io/downloads)

* [Packer](https://www.packer.io/downloads)

* [Terraform](https://www.terraform.io/downloads.html)

### Install and Authenticate the GCP SDK Command Line Tools

**If you are using [Cloud Shell](https://cloud.google.com/shell), you already have `gcloud` set up, and you can safely skip this step.**

To install the [GCP SDK Command Line Tools](https://cloud.google.com/sdk/docs/downloads-interactive), follow the installation instructions for your specific operating system.

After installation, authenticate `gcloud` with the following command:

``` console
gcloud auth login
```

## Create a New Project

Generate a project ID with the following command:
*Replace PROJECT_NAME with the name of your desired project*

``` console
export GOOGLE_PROJECT="PROJECT_NAME-$(cat /dev/random | head -c 5 | xxd -p)"
```

Using that project ID, create a new GCP [project](https://cloud.google.com/docs/overview#projects):

``` console
gcloud projects create $GOOGLE_PROJECT
```

And then set your `gcloud` config to use that project:

``` console
gcloud config set project $GOOGLE_PROJECT
```

### Link Billing Account to Project

Next, let's link a billing account to that project. To determine what billing accounts are available, run the following command:

``` console
gcloud alpha billing accounts list
```

Locate the `ACCOUNT_ID` for the billing account you want to use, and set the `GOOGLE_BILLING_ACCOUNT` environment variable. Replace the `XXXXXXX` with the `ACCOUNT_ID` you located with the previous command output:

``` console
export GOOGLE_BILLING_ACCOUNT="XXXXXXX"
```

So we can link the `GOOGLE_BILLING_ACCOUNT` with the previously created `GOOGLE_PROJECT` :

``` console
gcloud alpha billing projects link "$GOOGLE_PROJECT" --billing-account "$GOOGLE_BILLING_ACCOUNT"
```

### Enable Compute API

In order to deploy VMs to the project, we need to enable the compute API:

``` console
gcloud services enable compute.googleapis.com
```

### Create Terraform and Packer Service Account

Finally, let's create a Terraform & Packer Service Account user and generate a `terraform_sa_key.json` and `packer_sa_key.json` credentials file:

A [shell script](./setup_sa.sh) is provided that execute the require instructions for creating the required service accounts.

> ⚠️ **Warning**
>
> The `*_sa_key.json` credentials gives privileged access to this GCP project. Be careful to avoid leaking these credentials by accidentally committing them to version control systems such as `git` , or storing them where they are visible to others

Create a directory named cred and move the credentials files into it.

The cred directory should be added to `.gitignore` for safety.

Now set the *full path* of the newly created `packer_sa_key.json` file as `GOOGLE_APPLICATION_CREDENTIALS` environment variable.

``` console
export GOOGLE_APPLICATION_CREDENTIALS=$(realpath packer_sa_key.json)
```

### Ensure Required Environment Variables Are Set

Before moving onto the next steps, ensure the following environment variables are set:

* `GOOGLE_PROJECT` with your selected GCP project ID.
* `GOOGLE_APPLICATION_CREDENTIALS` with the *full path* to the Packer Service Account `packer_sa_key.json` credentials file created in the last step.

## Build HashiStack Golden Image with Packer

[Packer](https://www.packer.io/intro/index.html) is HashiCorp's open source tool for creating identical machine images for multiple platforms from a single source configuration.
The machine image created here can be customized through modifications to the [build configuration file](./packer.json) and the [shell script](./shared/scripts/install.sh).
