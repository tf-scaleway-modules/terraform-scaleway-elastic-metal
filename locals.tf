locals {
  #--------------------------------------------------------------
  # Server Expansion
  # Expands server definitions based on count parameter
  # count=3 with key "web" creates: web-01, web-02, web-03
  #--------------------------------------------------------------

  expanded_servers = merge([
    for name, config in var.servers : {
      for i in range(coalesce(config.count, 1)) :
      (coalesce(config.count, 1) > 1 ? "${name}-${format("%02d", i + 1)}" : name) => {
        base_name                   = name
        index                       = i + 1
        server_count                = coalesce(config.count, 1)
        offer                       = config.offer
        os                          = config.os
        os_version                  = config.os_version
        subscription_period         = coalesce(config.subscription_period, "hourly")
        hostname_base               = config.hostname
        description_base            = coalesce(config.description, "")
        tags                        = coalesce(config.tags, [])
        ssh_key_ids                 = coalesce(config.ssh_key_ids, [])
        install_config_afterward    = coalesce(config.install_config_afterward, false)
        service_user                = config.service_user
        service_password            = config.service_password
        user                        = config.user
        password                    = config.password
        reinstall_on_config_changes = coalesce(config.reinstall_on_config_changes, false)
        options                     = coalesce(config.options, [])
        private_networks            = coalesce(config.private_networks, [])
        flexible_ips                = coalesce(config.flexible_ips, [])
      }
    }
  ]...)

  #--------------------------------------------------------------
  # Server Configuration Processing
  # Merges default values with per-server configuration
  #--------------------------------------------------------------

  servers = {
    for name, config in local.expanded_servers : name => merge(config, {
      hostname = (
        config.server_count > 1
        ? "${coalesce(config.hostname_base, config.base_name)}-${format("%02d", config.index)}"
        : coalesce(config.hostname_base, name)
      )
      description = (
        config.server_count > 1 && config.description_base != ""
        ? "${config.description_base} ${format("%02d", config.index)}"
        : config.description_base
      )
      tags                 = distinct(concat(var.default_tags, config.tags))
      existing_ssh_key_ids = distinct(concat(var.default_ssh_key_ids, config.ssh_key_ids))
    })
  }

  #--------------------------------------------------------------
  # Flexible IP Flattening
  # Creates a flat map of flexible IPs for for_each iteration
  # Uses expanded server names for proper association
  #--------------------------------------------------------------

  flexible_ips = merge([
    for server_name, config in local.servers : {
      for idx, fip in config.flexible_ips : "${server_name}-fip-${idx}" => {
        server_name = server_name
        description = fip.description
        tags        = distinct(concat(var.default_tags, coalesce(fip.tags, [])))
        reverse     = fip.reverse
        is_ipv6     = coalesce(fip.is_ipv6, false)
      }
    }
  ]...)
}
