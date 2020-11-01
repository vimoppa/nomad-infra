# This file was autogenerate by the BETA 'packer hcl2_upgrade' command. We
# recommend double checking that everything is correct before going forward. We
# also recommend treating this file as disposable. The HCL2 blocks in this
# file can be moved to other files. For example, the variable blocks could be
# moved to their own 'variables.pkr.hcl' file, etc. Those files need to be
# suffixed with '.pkr.hcl' to be visible to Packer. To use multiple files at
# once they also need to be in the same folder. 'packer inspect folder/'
# will describe to you what is in that folder.

# All generated input variables will be of string type as this how Packer JSON
# views them; you can later on change their type. Read the variables type
# constraints documentation
# https://www.packer.io/docs/from-1.5/variables#type-constraints for more info.
variable "disk_size_gb" {
  type    = string
  default = "50"
}

variable "project" {
  type    = string
  default = ""
}

variable "source_image_family" {
  type    = string
  default = "ubuntu-1604-lts"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

# "timestamp" template function replacement
locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors onto a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/from-1.5/blocks/source
source "googlecompute" "hashistack" {
  # account_file        = "${var.account_file}"
  disk_size           = "${var.disk_size_gb}"
  image_description   = "HashiStack Image"
  image_name          = "hashistack"
  machine_type        = "n1-standard-1"
  project_id          = "${var.project}"
  source_image_family = "${var.source_image_family}"
  ssh_username        = "ubuntu"
  state_timeout       = "15m"
  zone                = "${var.zone}"
}

# a build block invokes sources and runs provisionning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/from-1.5/blocks/build
build {
  sources = ["source.googlecompute.hashistack"]

  provisioner "shell" {
    environment_vars = ["vault_version=1.5.3", "nomad_version=0.12.5", "fabio_version=1.5.14", "consul_version=1.8.4", "consul_template_version=0.25.1"]
    script           = "scripts/hashistack.sh"
  }
  provisioner "shell" {
    inline = ["sudo mkdir -p /opt/gruntwork", "git clone --branch v0.0.3 https://github.com/gruntwork-io/bash-commons.git /tmp/bash-commons", "sudo cp -r /tmp/bash-commons/modules/bash-commons/src /opt/gruntwork/bash-commons"]
  }
  provisioner "shell" {
    script = "scripts/install-dnsmasq"
  }
}
