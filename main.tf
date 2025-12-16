#--------------------------------------------------------------
# SSH Keys
#--------------------------------------------------------------

resource "scaleway_iam_ssh_key" "this" {
  for_each = var.ssh_keys

  name       = each.key
  public_key = each.value.public_key
  disabled   = each.value.disabled
  project_id = data.scaleway_account_project.this.id
}

#--------------------------------------------------------------
# Elastic Metal Servers
#--------------------------------------------------------------

resource "scaleway_baremetal_server" "this" {
  for_each = local.servers

  zone       = var.zone
  project_id = data.scaleway_account_project.this.id

  # Server identification
  name        = each.value.hostname
  hostname    = each.value.hostname
  description = each.value.description
  tags        = each.value.tags

  # Hardware and OS configuration
  offer = data.scaleway_baremetal_offer.this[each.key].offer_id
  os    = element(split("/", data.scaleway_baremetal_os.this[each.key].os_id), 1)

  # SSH access configuration
  ssh_key_ids = distinct(concat(
    each.value.existing_ssh_key_ids,
    [for key in scaleway_iam_ssh_key.this : key.id]
  ))
  install_config_afterward = each.value.install_config_afterward

  # Installation credentials
  service_user     = each.value.service_user
  service_password = each.value.service_password
  user             = each.value.user
  password         = each.value.password

  # Lifecycle configuration
  reinstall_on_config_changes = each.value.reinstall_on_config_changes

  # Server options
  dynamic "options" {
    for_each = each.value.options
    content {
      id         = options.value.id
      expires_at = options.value.expires_at
    }
  }

  # Private network attachments
  dynamic "private_network" {
    for_each = each.value.private_networks
    content {
      id = private_network.value.id
    }
  }

  # Operation timeouts
  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

#--------------------------------------------------------------
# Flexible IPs
#--------------------------------------------------------------

resource "scaleway_flexible_ip" "this" {
  for_each = local.flexible_ips

  zone       = var.zone
  project_id = data.scaleway_account_project.this.id
  server_id  = scaleway_baremetal_server.this[each.value.server_name].id

  description = each.value.description
  tags        = each.value.tags
  reverse     = each.value.reverse
  is_ipv6     = each.value.is_ipv6
}
