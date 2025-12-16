# provider "scaleway" {
#   zone = "fr-par-1"
# }

# To list available offers, run:
# scw baremetal offer list zone=fr-par-1

module "elastic_metal" {
  source = "../.."

  organization_id = "f3d8393e-008a-4fb2-a4ff-81b6fe5c01b0"
  project_name    = "default"
  zone            = "fr-par-2"

  servers = {
    web-01 = {
      offer               = "EM-A116X-SSD"             # Check available offers with: scw baremetal offer list
      os                  = "Ubuntu"                   # Check available OS with: scw baremetal os list zone=fr-par-1
      os_version          = "24.04 LTS (Noble Numbat)" # Optional: use 'scw baremetal os list' to see versions
      subscription_period = "hourly"                   # Options: "hourly" or "monthly"
      hostname            = "web-01"
      description         = "Web server 01"
      tags                = ["web", "production"]
      flexible_ips = [
        {
          description = "Primary failover IP"
          reverse     = "web-01.example.com"
        }
      ]
    }

    # web-02 = {
    #   offer               = "EM-A210R-HDD"
    #   os                  = "Ubuntu"
    #   os_version          = "22.04 LTS (Jammy Jellyfish)" # Use 'scw baremetal os list' to see versions
    #   subscription_period = "hourly"
    #   hostname            = "web-02"
    #   description         = "Web server 02"
    #   tags                = ["web", "production"]
    #   flexible_ips = [
    #     {
    #       description = "Primary failover IP"
    #       reverse     = "web-02.example.com"
    #     },
    #     {
    #       description = "IPv6 address"
    #       is_ipv6     = true
    #     }
    #   ]
    # }

    # db-01 = {
    #   offer                       = "EM-B312X-SSD"
    #   os                          = "Ubuntu"
    #   os_version                  = "24.04 LTS (Noble Numbat)" # Use 'scw baremetal os list' to see versions
    #   subscription_period         = "monthly"                  # Monthly billing for long-term servers
    #   hostname                    = "db-01"
    #   description                 = "Database server"
    #   tags                        = ["database", "production"]
    #   reinstall_on_config_changes = false
    #
    #   # Attach to private networks (VPC)
    #   # Get private network IDs with: scw vpc private-network list
    #   private_networks = [
    #     {
    #       id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    #     }
    #   ]
    #
    #   # Server options (e.g., remote access, additional storage)
    #   # Get option IDs from offer details: scw baremetal offer get <offer-id>
    #   options = [
    #     {
    #       id         = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    #       expires_at = "2025-12-31T23:59:59Z" # Optional expiration
    #     }
    #   ]
    # }
  }

  # Option 1: Reference existing SSH keys by ID
  default_ssh_key_ids = []

  # Option 2: Create new SSH keys (attached to all servers)
  # IMPORTANT: Replace with your real SSH public keys!
  # Generate a key with: ssh-keygen -t ed25519 -C "your-email@example.com"
  # Then copy the content of ~/.ssh/id_ed25519.pub here
  ssh_keys = {
    # Uncomment and add your real SSH public key:
    admin = {
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDGKYuZIcf54r6zoYDGc71Syt6CzUIuwtxSC55yrWpa7 test@leminnov.cloud"
    }
  }

  default_tags = ["managed-by-terraform", "environment:production"]

  timeouts = {
    create = "2h"
    update = "1h"
    delete = "30m"
  }
}
