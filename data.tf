################################################################################
# Data Sources
################################################################################

data "scaleway_account_project" "this" {
  name            = var.project_name
  organization_id = var.organization_id
}


#--------------------------------------------------------------
# Baremetal Offer Lookup
# Resolves offer names to offer IDs for each server
#--------------------------------------------------------------

data "scaleway_baremetal_offer" "this" {
  for_each = local.servers

  zone                = var.zone
  name                = each.value.offer
  subscription_period = each.value.subscription_period
}

#--------------------------------------------------------------
# Operating System Lookup
# Resolves OS names to OS IDs for each server
#--------------------------------------------------------------

data "scaleway_baremetal_os" "this" {
  for_each = local.servers

  zone = var.zone
  name = each.value.os
}
