#--------------------------------------------------------------
# Provider Configuration
#--------------------------------------------------------------

variable "project_id" {
  description = "ID of the Scaleway project that owns the SSH keys, servers and flexible IPs. Null uses the provider's default project; changing it replaces the resources"
  type        = string
  default     = null

  validation {
    condition     = var.project_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.project_id))
    error_message = "project_id must be a valid UUID."
  }
}

variable "zone" {
  description = "Zone where Elastic Metal servers are deployed (e.g. fr-par-2). Null uses the provider's default zone; changing it replaces the servers"
  type        = string
  default     = null

  validation {
    condition     = var.zone == null || can(regex("^[a-z]{2}-[a-z]{3}-[0-9]$", var.zone))
    error_message = "Zone must be in format: xx-xxx-N (e.g., fr-par-2)."
  }
}

#--------------------------------------------------------------
# Server Configuration
#--------------------------------------------------------------

variable "servers" {
  description = "Map of Elastic Metal servers to create. Use 'count' to create multiple identical servers with indexed names."
  type = map(object({
    count                       = optional(number, 1)
    offer                       = string
    os                          = string
    os_version                  = optional(string)
    subscription_period         = optional(string, "hourly")
    hostname                    = optional(string)
    description                 = optional(string, "")
    tags                        = optional(list(string), [])
    ssh_key_ids                 = optional(list(string), [])
    install_config_afterward    = optional(bool, false)
    service_user                = optional(string)
    service_password_version    = optional(number) # bump to apply a new server_passwords[<key>].service_password
    user                        = optional(string)
    password_version            = optional(number) # bump to apply a new server_passwords[<key>].password
    reinstall_on_config_changes = optional(bool, false)
    protected                   = optional(bool, false) # true makes the API refuse deletion, so destroy fails until it is set back to false
    cloud_init                  = optional(string)      # user data, stored in state in clear text: do not embed secrets; applied at boot, needs a reboot to change
    partitioning                = optional(string)      # JSON schema, applied on install or reinstall only
    options = optional(map(object({                     # keyed by option name (scw baremetal option list)
      expires_at = optional(string)
    })), {})
    private_networks = optional(list(object({
      id          = string
      ipam_ip_ids = optional(list(string)) # pins the private IPs; IPs already assigned stay if removed later
    })), [])
    flexible_ips = optional(list(object({
      description = optional(string)
      tags        = optional(list(string), [])
      reverse     = optional(string)
      is_ipv6     = optional(bool, false)
    })), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.servers : can(regex("^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9])$", k))])
    error_message = "Server keys must be valid identifiers (alphanumeric and hyphens, not starting or ending with hyphen)."
  }

  validation {
    condition     = alltrue([for k, v in var.servers : contains(["hourly", "monthly"], v.subscription_period)])
    error_message = "subscription_period must be either 'hourly' or 'monthly'."
  }

  validation {
    condition     = alltrue([for k, v in var.servers : v.count >= 1 && v.count <= 100])
    error_message = "Server count must be between 1 and 100."
  }

  validation {
    condition     = alltrue([for k, v in var.servers : v.cloud_init == null || length(v.cloud_init) <= 127998])
    error_message = "cloud_init must not exceed 127998 characters."
  }

  validation {
    condition     = alltrue([for k, v in var.servers : v.partitioning == null || can(jsondecode(v.partitioning))])
    error_message = "partitioning must be a valid JSON document."
  }

  validation {
    condition = alltrue([
      for k, v in var.servers : alltrue([
        for pn in v.private_networks : pn.ipam_ip_ids == null || alltrue([
          for id in pn.ipam_ip_ids : can(regex("^([a-z]{2}-[a-z]{3}(-[0-9])?/)?[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", id))
        ])
      ])
    ])
    error_message = "ipam_ip_ids entries must be UUIDs, optionally prefixed by a zone or region (e.g. fr-par-2/<uuid>)."
  }

  validation {
    condition = alltrue([
      for k, v in var.servers : alltrue([
        for fip in v.flexible_ips : fip.reverse == null || can(regex("^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,63}\\.?$", fip.reverse))
      ])
    ])
    error_message = "reverse must be a fully qualified hostname such as api.example.com."
  }
}

variable "server_passwords" {
  description = "Installation passwords per key of 'servers' (shared by every server expanded from that key), sent through write-only arguments so they never land in state. Provide them through TF_VAR_server_passwords, a CI secret or a vault. A new value is applied only when the matching password_version / service_password_version of the server changes"
  type = map(object({
    password         = optional(string)
    service_password = optional(string)
  }))
  default   = {}
  sensitive = true
  ephemeral = true
}

#--------------------------------------------------------------
# SSH Key Configuration
#--------------------------------------------------------------

variable "ssh_key_ids" {
  description = "Existing SSH key IDs to attach to all servers (merged with per-server ssh_key_ids)"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.ssh_key_ids : can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", id))])
    error_message = "All SSH key IDs must be valid UUIDs."
  }
}

variable "ssh_keys" {
  description = "Map of SSH keys to create and attach to all servers"
  type = map(object({
    public_key = string
    disabled   = optional(bool, false)
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.ssh_keys : can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|sk-ssh-ed25519@openssh.com|sk-ecdsa-sha2-nistp256@openssh.com)\\s+", v.public_key))])
    error_message = "All public keys must be valid SSH public keys (ssh-rsa, ssh-ed25519, or ecdsa)."
  }
}

#--------------------------------------------------------------
# Default Values
#--------------------------------------------------------------

variable "tags" {
  description = "Tags applied to all servers and flexible IPs (merged with their own tags)"
  type        = list(string)
  default     = []
}

variable "timeouts" {
  description = "Timeout configuration for server operations"
  type = object({
    create = optional(string, "1h")
    update = optional(string, "1h")
    delete = optional(string, "1h")
  })
  default = {}

  validation {
    condition     = alltrue([for t in values(var.timeouts) : can(regex("^(0|([0-9]+(\\.[0-9]+)?(ns|us|µs|ms|s|m|h))+)$", t))])
    error_message = "Timeouts must be durations such as 30m, 1h or 1h30m."
  }
}
