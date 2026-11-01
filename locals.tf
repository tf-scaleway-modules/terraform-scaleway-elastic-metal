locals {
  #--------------------------------------------------------------
  # Server Expansion
  # Expands server definitions based on count parameter
  # count=3 with key "web" creates: web-01, web-02, web-03
  #--------------------------------------------------------------

  servers = merge([
    for name, config in var.servers : {
      for i in range(config.count) :
      (config.count > 1 ? "${name}-${format("%02d", i + 1)}" : name) => {
        base_name = name
        config    = config
        hostname = (
          config.count > 1
          ? "${coalesce(config.hostname, name)}-${format("%02d", i + 1)}"
          : coalesce(config.hostname, name)
        )
        description = (
          config.count > 1 && config.description != ""
          ? "${config.description} ${format("%02d", i + 1)}"
          : config.description
        )
        tags        = distinct(concat(var.tags, config.tags))
        ssh_key_ids = distinct(concat(var.ssh_key_ids, config.ssh_key_ids))
      }
    }
  ]...)

  #--------------------------------------------------------------
  # Option Names
  # One lookup per distinct option name across all servers
  #--------------------------------------------------------------

  option_names = toset(flatten([for config in var.servers : keys(config.options)]))

  #--------------------------------------------------------------
  # Flexible IP Flattening
  # Creates a flat map of flexible IPs for for_each iteration
  # Uses expanded server names for proper association
  #--------------------------------------------------------------

  flexible_ips = merge([
    for server_name, server in local.servers : {
      for idx, fip in server.config.flexible_ips : "${server_name}-fip-${idx}" => {
        server_name = server_name
        description = fip.description
        tags        = distinct(concat(var.tags, fip.tags))
        reverse     = fip.reverse
        is_ipv6     = fip.is_ipv6
      }
    }
  ]...)
}
