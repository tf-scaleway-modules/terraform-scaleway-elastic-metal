resource "scaleway_baremetal_server" "this" {
  for_each = local.servers

  zone       = var.zone
  project_id = var.project_id

  name        = each.value.hostname
  hostname    = each.value.hostname
  description = each.value.description
  tags        = each.value.tags

  offer = data.scaleway_baremetal_offer.this[each.key].offer_id
  os    = data.scaleway_baremetal_os.this[each.key].os_id

  ssh_key_ids              = each.value.ssh_key_ids
  install_config_afterward = each.value.install_config_afterward

  service_user     = each.value.service_user
  service_password = each.value.service_password
  user             = each.value.user
  password         = each.value.password

  reinstall_on_config_changes = each.value.reinstall_on_config_changes

  dynamic "options" {
    for_each = each.value.options
    content {
      id         = options.value.id
      expires_at = options.value.expires_at
    }
  }

  dynamic "private_network" {
    for_each = each.value.private_networks
    content {
      id = private_network.value.id
    }
  }

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

resource "scaleway_flexible_ip" "this" {
  for_each = local.flexible_ips

  zone       = var.zone
  project_id = var.project_id
  server_id  = scaleway_baremetal_server.this[each.value.server_name].id

  description = each.value.description
  tags        = each.value.tags
  reverse     = each.value.reverse
  is_ipv6     = each.value.is_ipv6
}
