variable "project" {
  type    = string
  default = ""
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

variable "environment" {
  type    = string
  default = "staging"
}

variable "remote_state_storage_class" {
  type    = string
  default = "REGIONAL"
}

variable "source_image_family" {
  default     = "ubuntu-1604-lts"
  description = "Source image family. See packer config... i.e hashistack ucontext project image family"
}

variable "source_image_name" {
  default     = "hashistack"
  description = "Source image name."
}

variable "terraform_service_account" {
  default = {
    email  = "terraform@ucontex-app.iam.gserviceaccount.com",
    scopes = []
    #  scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
  type = object({
    email  = string,
    scopes = set(string)
  })
  description = "Service account to attach to the instance. See https://www.terraform.io/docs/providers/google/r/compute_instance_template.html#service_account."
}

variable "disk_size_gb" {
  default     = 50
  description = "Disk image size in GB"
}

variable "can_ip_forward" {
  default     = "false"
  description = ""
}

variable "key_name" {
  description = "The absolute path on disk to the SSH public key."
  default     = ""
  # default     = "~/.ssh/id_rsa.pub"
}

variable "wait_for_instances" {
  description = "Whether to wait for all instances to be created/updated before returning. Note that if this is set to true and the operation does not succeed, Terraform will continue trying until it times out."
  default     = "false"
}


# ---------------------------------------------------------------------------------------------------------------------
# MYSQL
# ---------------------------------------------------------------------------------------------------------------------

variable "mysql_version" {
  description = "The engine version of the database, e.g. `POSTGRES_9_6`. See https://cloud.google.com/sql/docs/features for supported versions."
  type        = string
  default     = "MYSQL_5_6"
}

variable "mysql_machine_type" {
  description = "The machine type to use, see https://cloud.google.com/sql/pricing for more details"
  type        = string
  default     = "db-n1-standard-1"
}

# ---------------------------------------------------------------------------------------------------------------------
# VPC NETWORK
# ---------------------------------------------------------------------------------------------------------------------

# For the example, we recommend a /16 network for the VPC. Note that when changing the size of the network,
# you will have to adjust the 'cidr_subnetwork_width_delta' in the 'vpc_network' -module accordingly.
variable "vpc_cidr_block" {
  description = "The IP address range of the VPC in CIDR notation. A prefix of /16 is recommended. Do not use a prefix higher than /27."
  type        = string
  default     = "10.6.0.0/16"
}

# For the example, we recommend a /16 network for the secondary range. Note that when changing the size of the network,
# you will have to adjust the 'cidr_subnetwork_width_delta' in the 'vpc_network' -module accordingly.
variable "vpc_secondary_cidr_block" {
  description = "The IP address range of the VPC's secondary address range in CIDR notation. A prefix of /16 is recommended. Do not use a prefix higher than /27."
  type        = string
  default     = "10.7.0.0/16"
}

variable "nat_ip" {
  description = "Public ip address"
  default     = null
}

variable "network_tier" {
  description = "Network network_tier"
  default     = "PREMIUM"
}

variable "authorized_networks" {
  default = [{
    name  = "sample-gcp-health-checkers-range"
    value = "0.0.0.0/0"
  }]
  type        = list(map(string))
  description = "List of mapped public networks authorized to access to the instances. Default - short range of GCP health-checkers IPs"
}

variable "named_ports" {
  description = "Named name and named port. https://cloud.google.com/load-balancing/docs/backend-service#named_ports"
  type = list(object({
    name = string
    port = number
  }))
  default = []
}

# ---------------------------------------------------------------------------------------------------------------------
# Mananged Instance Group
# ---------------------------------------------------------------------------------------------------------------------

variable "target_size" {
  description = "The target number of running instances for this managed or unmanaged instance group. This value should always be explicitly set unless this resource is attached to an autoscaler, in which case it should never be set."
  default     = 1
}

variable "distribution_policy_zones" {
  description = "The distribution policy, i.e. which zone(s) should instances be create in. Default is all zones in given region."
  type        = list(string)
  default     = []
}

variable "update_policy" {
  description = "The rolling update policy. https://www.terraform.io/docs/providers/google/r/compute_region_instance_group_manager.html#rolling_update_policy"
  type = list(object({
    max_surge_fixed              = number
    instance_redistribution_type = string
    max_surge_percent            = number
    max_unavailable_fixed        = number
    max_unavailable_percent      = number
    min_ready_sec                = number
    minimal_action               = string
    type                         = string
  }))
  default = []
}

/* health checks */

variable "health_check" {
  description = "Health check to determine whether instances are responsive and able to do work"
  type = object({
    type                = string
    initial_delay_sec   = number
    check_interval_sec  = number
    healthy_threshold   = number
    timeout_sec         = number
    unhealthy_threshold = number
    response            = string
    proxy_header        = string
    port                = number
    request             = string
    request_path        = string
    host                = string
  })
  default = {
    type                = "http"
    initial_delay_sec   = 30
    check_interval_sec  = 30
    healthy_threshold   = 1
    timeout_sec         = 10
    unhealthy_threshold = 5
    response            = ""
    proxy_header        = "NONE"
    port                = 80
    request             = ""
    request_path        = "/"
    host                = ""
  }
}

/* autoscaler */

variable "max_replicas" {
  description = "The maximum number of instances that the autoscaler can scale up to. This is required when creating or updating an autoscaler. The maximum number of replicas should not be lower than minimal number of replicas."
  default     = 10
}

variable "min_replicas" {
  description = "The minimum number of replicas that the autoscaler can scale down to. This cannot be less than 0."
  default     = 2
}

variable "cooldown_period" {
  description = "The number of seconds that the autoscaler should wait before it starts collecting information from a new instance."
  default     = 60
}

variable "autoscaling_cpu" {
  description = "Autoscaling, cpu utilization policy block as single element array. https://www.terraform.io/docs/providers/google/r/compute_autoscaler.html#cpu_utilization"
  type        = list(map(number))
  default     = []
}

variable "autoscaling_metric" {
  description = "Autoscaling, metric policy block as single element array. https://www.terraform.io/docs/providers/google/r/compute_autoscaler.html#metric"
  type = list(object({
    name   = string
    target = number
    type   = string
  }))
  default = []
}

variable "autoscaling_lb" {
  description = "Autoscaling, load balancing utilization policy block as single element array. https://www.terraform.io/docs/providers/google/r/compute_autoscaler.html#load_balancing_utilization"
  type        = list(map(number))
  default     = []
}

variable "autoscaling_enabled" {
  description = "Creates an autoscaler for the managed instance group"
  type        = bool
  default     = false
}

/* consul retry join tag */
variable "join_tag_vaule" {
  type    = string
  default = "autojoin"
}
