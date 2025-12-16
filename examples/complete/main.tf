# provider "scaleway" {
#   zone = "fr-par-2"
# }

# To list available offers, run:
# scw baremetal offer list zone=fr-par-2

module "elastic_metal" {
  source = "../.."

  organization_id = "f3d8393e-008a-4fb2-a4ff-81b6fe5c01b0"
  project_name    = "default"
  zone            = "fr-par-1"

  servers = {
    web-01 = {
      offer       = "EM-A210R-HDD" # Check available offers with: scw baremetal offer list
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
      offer       = "EM-A210R-HDD"
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
      offer                       = "EM-B312X-SSD"
      os                          = "Ubuntu"
      hostname                    = "db-01"
      description                 = "Database server"
      tags                        = ["database", "production"]
      reinstall_on_config_changes = false
    }
  }

  # Option 1: Reference existing SSH keys by ID
  default_ssh_key_ids = ["xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"]

  # Option 2: Create new SSH keys (attached to all servers)
  ssh_keys = {
    admin = {
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample admin@example.com"
    }
    deploy = {
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExample deploy@example.com"
    }
  }

  default_tags = ["managed-by-terraform", "environment:production"]

  timeouts = {
    create = "2h"
    update = "1h"
    delete = "30m"
  }
}
