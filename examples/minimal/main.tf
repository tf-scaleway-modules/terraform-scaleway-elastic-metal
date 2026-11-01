# provider "scaleway" {
#   zone = "fr-par-2"
# }

# To list available offers, run:
# scw baremetal offer list zone=fr-par-2

module "elastic_metal" {
  source = "../.."

  zone = "fr-par-1"

  servers = {
    web-server = {
      offer = "EM-A210R-HDD" # Check available offers with: scw baremetal offer list
      os    = "Ubuntu"
    }
  }

  ssh_key_ids = ["00000000-0000-0000-0000-000000000000"]
}
