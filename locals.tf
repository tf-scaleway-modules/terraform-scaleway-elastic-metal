locals {
  servers = {
    for name, config in var.servers : name => merge(config, {
      hostname    = coalesce(config.hostname, name)
      tags        = distinct(concat(var.default_tags, coalesce(config.tags, [])))
      ssh_key_ids = distinct(concat(var.default_ssh_key_ids, coalesce(config.ssh_key_ids, [])))
    })
  }

  flexible_ips = merge([
    for server_name, config in var.servers : {
      for idx, fip in coalesce(config.flexible_ips, []) : "${server_name}-${idx}" => {
        server_name = server_name
        description = fip.description
        tags        = distinct(concat(var.default_tags, coalesce(fip.tags, [])))
        reverse     = fip.reverse
        is_ipv6     = fip.is_ipv6
      }
    }
  ]...)
}
