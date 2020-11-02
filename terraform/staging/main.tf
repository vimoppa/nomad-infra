locals {
  name_prefix = "${var.project}-${var.environment}-${random_string.suffix.result}"

  server_max_instance = 3
  server_min_instance = 1
  client_max_instance = 5
  client_min_instance = 3
}

data "google_compute_zones" "available" {
  project = var.project
  region  = var.region
}

data "google_compute_image" "hashistack" {
  project = var.project
  name    = var.source_image_name
}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "random_string" "password" {
  length  = 20
  special = false
}

resource "random_string" "name" {
  length  = 10
  special = false
  number  = false
  upper   = false
}

# ---------------------------------------------------------------------------------------------------------------------
# Create a Management Network for shared services
# ---------------------------------------------------------------------------------------------------------------------

module "vpc_network" {
  # source = "github.com/gruntwork-io/terraform-google-network.git//modules/vpc-network"
  source = "../modules/vpc-network"

  name_prefix = "${var.environment}-${random_string.suffix.result}"
  project     = var.project
  region      = var.region

  cidr_block           = var.vpc_cidr_block
  secondary_cidr_block = var.vpc_secondary_cidr_block
}

resource "google_compute_firewall" "allow-ingress-from-iap" {
  name          = "allow-ingress-from-iap"
  network       = module.vpc_network.network
  source_ranges = ["35.235.240.0/20"]

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }
}

# resource "google_compute_firewall" "allow_ssh_office" {
#   name    = "allow-ssh-office"
#   network = module.vpc_network.network

#   allow {
#     protocol = "tcp"
#     ports    = ["22"]
#   }

#   target_tags = ["allow-ssh"]
# }

resource "google_compute_firewall" "consul-http" {
  name          = "consul-http"
  direction     = "INGRESS"
  project       = var.project
  network       = module.vpc_network.network
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["8500"]
  }
}

resource "google_compute_firewall" "nomad-http" {
  name          = "nomad-http"
  direction     = "INGRESS"
  project       = var.project
  network       = module.vpc_network.network
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["4646"]
  }
}

resource "google_compute_firewall" "vault-http" {
  name          = "vault-http"
  direction     = "INGRESS"
  project       = var.project
  network       = module.vpc_network.network
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["8200"]
  }
}

resource "google_compute_firewall" "fabio-lb-http" {
  name          = "fabio-lb-http"
  direction     = "INGRESS"
  project       = var.project
  network       = module.vpc_network.network
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["9998"]
  }
}

# Specify which traffic are allow internally within the gcp network.
resource "google_compute_firewall" "internal" {
  name          = "internal"
  network       = module.vpc_network.network
  source_ranges = [var.vpc_cidr_block]
  # source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
}


resource "google_compute_firewall" "services_endpoint" {
  name          = "external"
  direction     = "INGRESS"
  project       = var.project
  network       = module.vpc_network.network
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# Create the bastion host to access private instances
# ---------------------------------------------------------------------------------------------------------------------

# module "bastion_host" {
#   # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
#   # to a specific version of the modules, such as the following example:
#   # source = "github.com/gruntwork-io/terraform-google-network.git//modules/bastion-host?ref=v0.1.2"
#   source = "../modules/bastion-host"

#   instance_name = "bastion-host-${var.environment}-${random_string.suffix.result}"
#   subnetwork    = module.vpc_network.public_subnetwork

#   project = var.project
#   zone    = var.zone
#   sshkeys = "ubuntu:${file(var.key_name)}"
# }

# ---------------------------------------------------------------------------------------------------------------------
# Create Server Instances and Managed Instance Group
# ---------------------------------------------------------------------------------------------------------------------

module "server_instance_template" {
  source               = "../modules/instance_template"
  region               = var.region
  project_id           = var.project
  network              = module.vpc_network.network
  subnetwork           = module.vpc_network.public_subnetwork
  service_account      = var.terraform_service_account
  name_prefix          = "nomad-server-template-${var.environment}"
  source_image         = data.google_compute_image.hashistack.name
  source_image_project = data.google_compute_image.hashistack.project
  source_image_family  = data.google_compute_image.hashistack.family
  disk_size_gb         = var.disk_size_gb
  tags                 = [var.join_tag_vaule]
  can_ip_forward       = var.can_ip_forward
  access_config = [
    {
      nat_ip       = null
      network_tier = null
    }
  ]
  startup_script = templatefile(
    "scripts/instance-setup.sh.tmpl",
    {
      bootstrap_expect = local.server_min_instance
      datacenter       = var.region
      # region           = "gcp"
      project_name = var.project
      tag_value    = var.join_tag_vaule
    }
  )
}

module "server_mig" {
  source                    = "../modules/mig"
  project_id                = var.project
  region                    = var.region
  network                   = module.vpc_network.network
  subnetwork                = module.vpc_network.public_subnetwork
  subnetwork_project        = var.project
  hostname                  = "server-${random_string.suffix.result}"
  instance_template         = module.server_instance_template.self_link
  wait_for_instances        = var.wait_for_instances
  target_pools              = [google_compute_target_pool.server.self_link]
  distribution_policy_zones = var.distribution_policy_zones
  update_policy             = var.update_policy
  named_ports               = var.named_ports
  target_size               = var.target_size

  /* health check */
  # health_check = var.health_check

  /* autoscaler */
  autoscaling_enabled = var.autoscaling_enabled
  max_replicas        = local.server_max_instance
  min_replicas        = local.server_min_instance
  cooldown_period     = var.cooldown_period
  autoscaling_cpu     = var.autoscaling_cpu
  autoscaling_metric  = var.autoscaling_metric
  autoscaling_lb      = var.autoscaling_lb
}

resource "google_compute_target_pool" "server" {
  name = "server-${random_string.suffix.result}"

  session_affinity = "NONE"
}

# ---------------------------------------------------------------------------------------------------------------------
# Create Client Instances and Managed Instance Group
# ---------------------------------------------------------------------------------------------------------------------

module "client_instance_template" {
  source               = "../modules/instance_template"
  region               = var.region
  project_id           = var.project
  network              = module.vpc_network.network
  subnetwork           = module.vpc_network.public_subnetwork
  service_account      = var.terraform_service_account
  name_prefix          = "nomad-client-template-${var.environment}"
  source_image         = data.google_compute_image.hashistack.name
  source_image_project = data.google_compute_image.hashistack.project
  source_image_family  = data.google_compute_image.hashistack.family
  disk_size_gb         = var.disk_size_gb
  tags                 = [var.join_tag_vaule]
  can_ip_forward       = var.can_ip_forward
  access_config = [
    {
      nat_ip       = null
      network_tier = null
    }
  ]
  startup_script = templatefile(
    "scripts/instance-setup.sh.tmpl",
    {
      /*
      expected bootstrap client would mock target_size.
      Recommended; bootstrap_expect = local.server_min_instance
      */
      bootstrap_expect = var.target_size
      datacenter       = var.region
      # region           = "gcp"
      project_name = var.project,
      tag_value    = var.join_tag_vaule
    }
  )
}

module "client_mig" {
  source                    = "../modules/mig"
  project_id                = var.project
  region                    = var.region
  network                   = module.vpc_network.network
  subnetwork                = module.vpc_network.public_subnetwork
  subnetwork_project        = var.project
  hostname                  = "client-${random_string.suffix.result}"
  instance_template         = module.client_instance_template.self_link
  wait_for_instances        = var.wait_for_instances
  target_pools              = [google_compute_target_pool.client.self_link]
  distribution_policy_zones = var.distribution_policy_zones
  update_policy             = var.update_policy
  named_ports               = var.named_ports
  target_size               = var.target_size

  /* health check */
  # health_check = var.health_check

  /* autoscaler */
  autoscaling_enabled = var.autoscaling_enabled
  max_replicas        = local.client_max_instance
  min_replicas        = local.client_min_instance
  cooldown_period     = var.cooldown_period
  autoscaling_cpu     = var.autoscaling_cpu
  autoscaling_metric  = var.autoscaling_metric
  autoscaling_lb      = var.autoscaling_lb
}

resource "google_compute_target_pool" "client" {
  name = "client-${random_string.suffix.result}"

  session_affinity = "NONE"
}


# ---------------------------------------------------------------------------------------------------------------------
# CREATING A POSTGRES INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

# module "mysql" {
#   # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
#   # to a specific version of the modules, such as the following example:
#   # source = "github.com/gruntwork-io/terraform-google-sql.git//modules/cloud-sql?ref=v0.2.0"
#   source = "../modules/cloud-sql"

#   project = var.project
#   region  = var.region
#   name    = "${var.project}-mysql-${var.environment}-${random_string.suffix.result}"
#   db_name = "${var.project}-mysql-${var.environment}-${random_string.suffix.result}"

#   engine       = var.mysql_version
#   machine_type = var.mysql_machine_type

#   master_zone = var.zone

#   # These together will construct the master_user privileges, i.e.
#   # 'master_user_name'@'master_user_host' IDENTIFIED BY 'master_user_password'.
#   # These should typically be set as the environment variable TF_VAR_master_user_password, etc.
#   # so you don't check these into source control."
#   master_user_password = random_string.password.result

#   master_user_name = random_string.name.result
#   master_user_host = "%"

#   # To make it easier to test this example, we are giving the servers public IP addresses and allowing inbound
#   # connections from anywhere. In real-world usage, your servers should live in private subnets, only have private IP
#   # addresses, and only allow access from specific trusted networks, servers or applications in your VPC.
#   enable_public_internet_access = true

#   # Default setting for this is 'false' in 'variables.tf'
#   # In the test cases, we're setting this to true, to test forced SSL.
#   require_ssl = false

#   authorized_networks = [
#     {
#       name  = "allow-all-inbound"
#       value = "0.0.0.0/0"
#     },
#   ]

#   # Set auto-increment flags to test the
#   # feature during automated testing
#   database_flags = [
#     {
#       name  = "auto_increment_increment"
#       value = "5"
#     },
#     {
#       name  = "auto_increment_offset"
#       value = "5"
#     },
#   ]

#   custom_labels = {
#     test-id = "mysql-public-ip"
#   }
# }

# ---------------------------------------------------------------------------------------------------------------------
# CREATING A DNS PUBLIC ZONE
# ---------------------------------------------------------------------------------------------------------------------

# module "dns_public_zone" {
#   source     = "terraform-google-modules/cloud-dns/google"
#   project_id = var.project
#   type       = "public"
#   name       = ""
#   domain     = ""
# }
