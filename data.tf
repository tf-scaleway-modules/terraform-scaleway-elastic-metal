data "scaleway_baremetal_offer" "this" {
  for_each = local.servers

  zone = var.zone
  name = each.value.offer
}

data "scaleway_baremetal_os" "this" {
  for_each = local.servers

  zone = var.zone
  name = each.value.os
}
