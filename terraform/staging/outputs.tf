# ---------------------------------------------------------------------------------------------------------------------
# DNS PUBLIC ZONE
# ---------------------------------------------------------------------------------------------------------------------

# output "name_servers" {
#   description = "Zone name servers."
#   value       = module.dns_public_zone.name_servers
# }

# ---------------------------------------------------------------------------------------------------------------------
# MYSQL
# ---------------------------------------------------------------------------------------------------------------------

# output "mysql_conn" {
#   value       = module.mysql.master_proxy_connection
#   description = "The connection name of the master instance to be used in connection strings"
# }

# output "mysql_user_name" {
#   value       = random_string.name.result
#   description = "The password for the default user. If not set, a random one will be generated and available in the generated_user_password output variable."
# }

# output "mysql_user_pass" {
#   value       = random_string.password.result
#   description = "The password for the default user. If not set, a random one will be generated and available in the generated_user_password output variable."
# }

# output "mysql_public_ip_address" {
#   description = "The first public (PRIMARY) IPv4 address assigned for the master instance"
#   value       = module.mysql.master_public_ip_address
# }

# ---------------------------------------------------------------------------------------------------------------------
# VPC NETWORK
# ---------------------------------------------------------------------------------------------------------------------

output "vpc_id" {
  value = module.vpc_network.id
}

output "network" {
  description = "A reference (self_link) to the VPC network"
  value       = module.vpc_network.network
}

output "avaliable_compute_zones" {
  value = data.google_compute_zones.available
}
