#--------------------------------------------------------------
# Project Output
#--------------------------------------------------------------

output "project_id" {
  description = "The Scaleway project ID"
  value       = data.scaleway_account_project.this.id
}

#--------------------------------------------------------------
# Server Outputs
#--------------------------------------------------------------

output "servers" {
  description = "Map of all Elastic Metal server resources"
  value       = scaleway_baremetal_server.this
}

output "server_ids" {
  description = "Map of server names to their IDs"
  value       = { for name, server in scaleway_baremetal_server.this : name => server.id }
}

output "server_ips" {
  description = "Map of server names to their public IPv4 addresses"
  value = {
    for name, server in scaleway_baremetal_server.this : name => [
      for ip in server.ips : ip.address if ip.version == "IPv4"
    ]
  }
}

output "server_ipv6s" {
  description = "Map of server names to their public IPv6 addresses"
  value = {
    for name, server in scaleway_baremetal_server.this : name => [
      for ip in server.ips : ip.address if ip.version == "IPv6"
    ]
  }
}

output "server_private_ips" {
  description = "Map of server names to their private network IPs"
  value = {
    for name, server in scaleway_baremetal_server.this : name => [
      for pn in server.private_network : pn.vlan_id
    ]
  }
}

#--------------------------------------------------------------
# Offer Outputs
#--------------------------------------------------------------

output "offers" {
  description = "Map of server names to their resolved offer details"
  value       = { for name, offer in data.scaleway_baremetal_offer.this : name => offer }
}

#--------------------------------------------------------------
# Flexible IP Outputs
#--------------------------------------------------------------

output "flexible_ips" {
  description = "Map of all Flexible IP resources"
  value       = scaleway_flexible_ip.this
}

output "flexible_ip_addresses" {
  description = "Map of server names to their flexible IP addresses"
  value = {
    for name, config in var.servers : name => [
      for key, fip in scaleway_flexible_ip.this : fip.ip_address
      if startswith(key, "${name}-")
    ]
  }
}

#--------------------------------------------------------------
# SSH Key Outputs
#--------------------------------------------------------------

output "ssh_keys" {
  description = "Map of all created SSH key resources"
  value       = scaleway_iam_ssh_key.this
}

output "ssh_key_ids" {
  description = "Map of SSH key names to their IDs"
  value       = { for name, key in scaleway_iam_ssh_key.this : name => key.id }
}
