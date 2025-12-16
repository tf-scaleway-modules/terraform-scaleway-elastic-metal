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
  description = "Map of Elastic Metal servers to create"
  type = map(object({
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
    user                        = optional(string)
    password                    = optional(string)
    reinstall_on_config_changes = optional(bool, false)
    options = optional(list(object({
      id         = string
      expires_at = optional(string)
    })), [])
    private_networks = optional(list(object({
      id = string
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
    condition     = alltrue([for k, v in var.servers : can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", k)) || length(k) == 1])
    error_message = "Server keys must be valid identifiers (alphanumeric and hyphens, not starting or ending with hyphen)."
  }

  validation {
    condition     = alltrue([for k, v in var.servers : contains(["hourly", "monthly"], coalesce(v.subscription_period, "hourly"))])
    error_message = "subscription_period must be either 'hourly' or 'monthly'."
  }
}

#--------------------------------------------------------------
# SSH Key Configuration
#--------------------------------------------------------------

variable "default_ssh_key_ids" {
  description = "Default list of existing SSH key IDs to attach to all servers (merged with per-server ssh_key_ids)"
  type        = list(string)
  default     = []
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
}
