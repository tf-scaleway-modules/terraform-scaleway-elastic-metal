# provider "scaleway" {
#   zone = "fr-par-1"
# }

# To list available offers, run:
# scw baremetal offer list zone=fr-par-1

module "elastic_metal" {
  source = "../.."

  organization_id = "00000000-0000-0000-0000-000000000000"
  project_name    = "default"
  zone            = "fr-par-2"

  servers = {
    # Using count to create multiple identical servers
    # This creates: web-01, web-02, web-03
    web = {
      count               = 3                          # Creates web-01, web-02, web-03
      offer               = "EM-A610R-NVME"            # Check available offers with: scw baremetal offer list
      os                  = "Ubuntu"                   # Check available OS with: scw baremetal os list zone=fr-par-2
      os_version          = "24.04 LTS (Noble Numbat)" # Optional: use 'scw baremetal os list' to see versions
      subscription_period = "hourly"                   # Options: "hourly" or "monthly"
      description         = "Web server"               # Becomes "Web server 01", "Web server 02", etc.
      tags                = ["web", "production"]
      flexible_ips = [
        {
          description = "Primary failover IP"
        }
      ]
    }

    # Single server without count (or count = 1)
    # api = {
    #   offer               = "EM-A610R-NVME"
    #   os                  = "Ubuntu"
    #   os_version          = "24.04 LTS (Noble Numbat)"
    #   subscription_period = "hourly"
    #   hostname            = "api-server"              # Custom hostname (not indexed)
    #   description         = "API Gateway server"
    #   tags                = ["api", "production"]
    # }

    # Database cluster with count
    # db = {
    #   count                       = 2                          # Creates db-01, db-02
    #   offer                       = "EM-B312X-SSD"
    #   os                          = "Ubuntu"
    #   os_version                  = "24.04 LTS (Noble Numbat)"
    #   subscription_period         = "monthly"                  # Monthly billing for long-term servers
    #   description                 = "Database server"          # Becomes "Database server 01", etc.
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
      public_key = "ssh-ed25519 sdfsdfsdfsdfsdfiuosdfsdfsdfsdfsdfiuoss test@leminnov.cloud"
    }
  }

  default_tags = ["managed-by-terraform", "environment:production"]

  timeouts = {
    create = "2h"
    update = "1h"
    delete = "30m"
  }
}
