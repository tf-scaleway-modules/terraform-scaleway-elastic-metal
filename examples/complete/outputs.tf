output "project_id" {
  description = "The resolved Scaleway project ID"
  value       = module.elastic_metal.project_id
}

output "server_ids" {
  description = "IDs of the created servers"
  value       = module.elastic_metal.server_ids
}

output "server_ips" {
  description = "Public IPv4 addresses of the servers"
  value       = module.elastic_metal.server_ips
}

output "server_ipv6s" {
  description = "Public IPv6 addresses of the servers"
  value       = module.elastic_metal.server_ipv6s
}

output "flexible_ip_addresses" {
  description = "Flexible IP addresses per server"
  value       = module.elastic_metal.flexible_ip_addresses
}

output "ssh_key_ids" {
  description = "IDs of created SSH keys"
  value       = module.elastic_metal.ssh_key_ids
}

output "servers" {
  description = "Full server resources"
  value       = module.elastic_metal.servers
  sensitive   = true
}
