provider "scaleway" {
  zone = "fr-par-2"
}

module "elastic_metal" {
  source = "../.."

  zone       = "fr-par-2"
  project_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

  servers = {
    web-01 = {
      offer       = "EM-A115X-SSD"
      os          = "Ubuntu"
      hostname    = "web-01"
      description = "Web server 01"
      tags        = ["web", "production"]
      flexible_ips = [
        {
          description = "Primary failover IP"
          reverse     = "web-01.example.com"
        }
      ]
    }

    web-02 = {
      offer       = "EM-A115X-SSD"
      os          = "Ubuntu"
      hostname    = "web-02"
      description = "Web server 02"
      tags        = ["web", "production"]
      flexible_ips = [
        {
          description = "Primary failover IP"
          reverse     = "web-02.example.com"
        },
        {
          description = "IPv6 address"
          is_ipv6     = true
        }
      ]
    }

    db-01 = {
      offer                       = "EM-A410X-SSD"
      os                          = "Ubuntu"
      hostname                    = "db-01"
      description                 = "Database server"
      tags                        = ["database", "production"]
      reinstall_on_config_changes = false
    }
  }

  default_ssh_key_ids = ["xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"]
  default_tags        = ["managed-by-terraform", "environment:production"]

  timeouts = {
    create = "2h"
    update = "1h"
    delete = "30m"
  }
}
