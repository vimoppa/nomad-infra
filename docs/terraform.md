# terraform

## Requirements

* gcloud & gcloud service account
* terraform

## Workflow

add service account path into the environment

``` bash
export GOOGLE_APPLICATION_CREDENTIALS='/path/to/service/account'.json
```

Authenticate gcloud cli

``` bash
    gcloud auth application-default login --no-launch-browser
```

only test terraform declarations from local on staging. Production should be opinionatedly run within a terraform github action.

``` bash

cd staging

```

initialize terraform and pull dependencies.

``` bash
terraform init
```

validate the terraform declarations.

``` bash
terraform plan

```

apply the declarations to the the project.

``` bash
terraform apply
```
