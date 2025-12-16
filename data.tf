################################################################################
# Data Sources
################################################################################

data "scaleway_account_project" "this" {
  name            = var.project_name
  organization_id = var.organization_id
}

#--------------------------------------------------------------
# Baremetal Offer Lookup
# Resolves offer names to offer IDs for each unique server definition
# Uses var.servers (base definitions) to avoid duplicate lookups for count > 1
#--------------------------------------------------------------

data "scaleway_baremetal_offer" "this" {
  for_each = var.servers

  zone                = var.zone
  name                = each.value.offer
  subscription_period = coalesce(each.value.subscription_period, "hourly")
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
