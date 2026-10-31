#--------------------------------------------------------------
# SSH Keys
#--------------------------------------------------------------

resource "scaleway_iam_ssh_key" "this" {
  for_each = var.ssh_keys

  name       = each.key
  public_key = each.value.public_key
  disabled   = each.value.disabled
  project_id = var.project_id
}

#--------------------------------------------------------------
# Elastic Metal Servers
#--------------------------------------------------------------

resource "scaleway_baremetal_server" "this" {
  for_each = local.servers

  zone       = var.zone
  project_id = var.project_id

  # Server identification
  name        = each.value.hostname
  hostname    = each.value.hostname
  description = each.value.description
  tags        = each.value.tags

  # Hardware and OS configuration (lookup by base_name for count > 1 support)
  offer = data.scaleway_baremetal_offer.this[each.value.base_name].offer_id
  os    = element(split("/", data.scaleway_baremetal_os.this[each.value.base_name].os_id), 1)

  # SSH access configuration
  ssh_key_ids = distinct(concat(
    each.value.ssh_key_ids,
    [for key in scaleway_iam_ssh_key.this : key.id]
  ))
  install_config_afterward = each.value.config.install_config_afterward

  # Installation credentials: passwords are ephemeral and only reach write-only arguments
  service_user                = each.value.config.service_user
  service_password_wo         = try(var.server_passwords[each.value.base_name].service_password, null)
  service_password_wo_version = each.value.config.service_password_version
  user                        = each.value.config.user
  password_wo                 = try(var.server_passwords[each.value.base_name].password, null)
  password_wo_version         = each.value.config.password_version

  # Lifecycle configuration
  reinstall_on_config_changes = each.value.config.reinstall_on_config_changes
  protected                   = each.value.config.protected

  # Install-time content
  cloud_init   = each.value.config.cloud_init
  partitioning = each.value.config.partitioning

  # Server options
  dynamic "options" {
    for_each = each.value.config.options
    content {
      id         = data.scaleway_baremetal_option.this[options.key].option_id
      expires_at = options.value.expires_at
    }
  }

  # Private network attachments
  dynamic "private_network" {
    for_each = each.value.config.private_networks
    content {
      id          = private_network.value.id
      ipam_ip_ids = private_network.value.ipam_ip_ids
    }
  }

  # Ensure SSH keys are created before the server
  depends_on = [scaleway_iam_ssh_key.this]

  # Operation timeouts
  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  lifecycle {
    precondition {
      condition     = length(each.value.ssh_key_ids) > 0 || length(var.ssh_keys) > 0
      error_message = "At least one SSH key must be provided via 'ssh_key_ids', per-server 'ssh_key_ids', or 'ssh_keys'."
    }
  }
}

#--------------------------------------------------------------
# Flexible IPs
#--------------------------------------------------------------

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
