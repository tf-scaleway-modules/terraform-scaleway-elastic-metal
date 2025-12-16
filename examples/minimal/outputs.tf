output "server_ids" {
  description = "IDs of the created servers"
  value       = module.elastic_metal.server_ids
}

output "server_ips" {
  description = "Public IPv4 addresses of the servers"
  value       = module.elastic_metal.server_ips
}
