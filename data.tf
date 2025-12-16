#--------------------------------------------------------------
# Baremetal Offer Lookup
# Resolves offer names to offer IDs for each server
#--------------------------------------------------------------

data "scaleway_baremetal_offer" "this" {
  for_each = local.servers

  zone = var.zone
  name = each.value.offer
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
