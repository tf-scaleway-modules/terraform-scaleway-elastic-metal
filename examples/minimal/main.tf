provider "scaleway" {
  zone = "fr-par-2"
}

module "elastic_metal" {
  source = "../.."

  zone = "fr-par-2"

  servers = {
    web-server = {
      offer = "EM-A115X-SSD"
      os    = "Ubuntu"
    }
  }

  default_ssh_key_ids = ["xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"]
}
