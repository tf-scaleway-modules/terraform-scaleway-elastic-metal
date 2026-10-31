#--------------------------------------------------------------
# Provider Configuration
#--------------------------------------------------------------

variable "organization_id" {
  description = "Scaleway organization ID"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.organization_id))
    error_message = "Organization ID must be a valid UUID."
  }
}

variable "project_name" {
  description = "Name of the Scaleway project"
  type        = string
  default     = "default"
}

variable "zone" {
  description = "Zone where Elastic Metal servers will be deployed"
  type        = string
  default     = "fr-par-2"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]{3}-[0-9]$", var.zone))
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
    service_password            = optional(string)
    service_password_wo         = optional(string) # write-only, never stored in state
    service_password_wo_version = optional(number) # bump to apply a new service_password_wo
    user                        = optional(string)
    password                    = optional(string)
    password_wo                 = optional(string) # write-only, never stored in state
    password_wo_version         = optional(number) # bump to apply a new password_wo
    reinstall_on_config_changes = optional(bool, false)
    protected                   = optional(bool, false) # true makes the API refuse deletion, so destroy fails until it is set back to false
    cloud_init                  = optional(string)      # user data, stored in state in clear text: do not embed secrets; applied at boot, needs a reboot to change
    partitioning                = optional(string)      # JSON schema, applied on install or reinstall only
    options = optional(list(object({
      id         = string
      expires_at = optional(string)
    })), [])
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
    condition     = alltrue([for k, v in var.servers : contains(["hourly", "monthly"], coalesce(v.subscription_period, "hourly"))])
    error_message = "subscription_period must be either 'hourly' or 'monthly'."
  }

  validation {
    condition     = alltrue([for k, v in var.servers : coalesce(v.count, 1) >= 1 && coalesce(v.count, 1) <= 100])
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
        for pn in coalesce(v.private_networks, []) : pn.ipam_ip_ids == null || alltrue([
          for id in pn.ipam_ip_ids : can(regex("^([a-z]{2}-[a-z]{3}(-[0-9])?/)?[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", id))
        ])
      ])
    ])
    error_message = "ipam_ip_ids entries must be UUIDs, optionally prefixed by a zone or region (e.g. fr-par-2/<uuid>)."
  }
}

#--------------------------------------------------------------
# SSH Key Configuration
#--------------------------------------------------------------

variable "default_ssh_key_ids" {
  description = "Default list of existing SSH key IDs to attach to all servers (merged with per-server ssh_key_ids)"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.default_ssh_key_ids : can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", id))])
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

variable "default_tags" {
  description = "Default tags to apply to all servers (merged with per-server tags)"
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
