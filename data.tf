################################################################################
# Data Sources
################################################################################

#--------------------------------------------------------------
# Baremetal Offer Lookup
# Resolves offer names to offer IDs for each unique server definition
# Uses var.servers (base definitions) to avoid duplicate lookups for count > 1
#--------------------------------------------------------------

data "scaleway_baremetal_offer" "this" {
  for_each = var.servers

  zone                = var.zone
  name                = each.value.offer
  subscription_period = each.value.subscription_period
}

#--------------------------------------------------------------
# Operating System Lookup
# Resolves OS names to OS IDs for each unique server definition
# Uses var.servers (base definitions) to avoid duplicate lookups for count > 1
#--------------------------------------------------------------

data "scaleway_baremetal_os" "this" {
  for_each = var.servers

  zone    = var.zone
  name    = each.value.os
  version = each.value.os_version
}

#--------------------------------------------------------------
# Server Option Lookup
# Resolves option names to option IDs, once per distinct name
#--------------------------------------------------------------

data "scaleway_baremetal_option" "this" {
  for_each = local.option_names

  zone = var.zone
  name = each.key
}
