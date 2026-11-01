# Scaleway Elastic Metal Terraform Module

[![Apache 2.0][apache-shield]][apache]
[![Terraform][terraform-badge]][terraform-url]
[![Scaleway Provider][scaleway-badge]][scaleway-url]
[![Latest Release][release-badge]][release-url]

A production-ready Terraform module for creating and managing **Scaleway Elastic Metal** (bare metal) servers with support for multiple instances, flexible IPs, SSH key management, and private networks.

## Features

- **Multiple Servers** - Deploy and manage multiple Elastic Metal servers with a single module call
- **Server Count** - Use `count` parameter to create multiple identical servers (e.g., `web` with `count=3` creates `web-01`, `web-02`, `web-03`)
- **Flexible IPs** - Attach multiple IPv4/IPv6 flexible IPs per server for failover scenarios
- **SSH Key Management** - Create new SSH keys or reference existing ones
- **Private Networks** - Connect servers to Scaleway VPC private networks
- **Server Options** - Attach server options by name, with expiration dates
- **Write-only Passwords** - Installation passwords are ephemeral and never stored in state
- **Configurable Timeouts** - Customize create/update/delete operation timeouts
- **Tag Inheritance** - Module tags automatically merged with per-server tags

## Usage

> **Note:** To list available Elastic Metal offers and operating systems in your zone, run:
> ```bash
> # List available offers
> scw baremetal offer list zone=fr-par-2
>
> # List available operating systems
> scw baremetal os list zone=fr-par-2
> ```

### Minimal Example

```hcl
module "elastic_metal" {
  source = "path/to/module"

  zone = "fr-par-2"

  servers = {
    web-server = {
      offer = "EM-A210R-HDD"  # Use: scw baremetal offer list
      os    = "Ubuntu"
    }
  }

  ssh_key_ids = ["00000000-0000-0000-0000-000000000000"]
}
```

### Complete Example

```hcl
module "elastic_metal" {
  source = "path/to/module"

  project_id = "00000000-0000-0000-0000-000000000000" # omit to use the provider's default project
  zone       = "fr-par-2"                             # omit to use the provider's default zone

  servers = {
    # Using count to create multiple identical servers
    # This creates: web-01, web-02, web-03
    web = {
      count               = 3  # Creates web-01, web-02, web-03
      offer               = "EM-A210R-HDD"
      os                  = "Ubuntu"
      os_version          = "22.04 LTS (Jammy Jellyfish)"
      description         = "Web server"  # Becomes "Web server 01", etc.
      tags                = ["web", "production"]
      flexible_ips = [
        {
          description = "Primary failover IP"
        }
      ]
    }

    # Single server (count = 1 is default)
    api = {
      offer       = "EM-A210R-HDD"
      os          = "Ubuntu"
      os_version  = "22.04 LTS (Jammy Jellyfish)"
      hostname    = "api-gateway"  # Custom hostname
      description = "API Gateway server"
      tags        = ["api", "production"]
    }

    # Database cluster with count
    db = {
      count                       = 2  # Creates db-01, db-02
      offer                       = "EM-B312X-SSD"
      os                          = "Ubuntu"
      os_version                  = "24.04 LTS (Noble Numbat)"
      subscription_period         = "monthly"
      description                 = "Database server"
      tags                        = ["database", "production"]
      reinstall_on_config_changes = false

      # Attach to private networks (VPC)
      private_networks = [
        { id = "00000000-0000-0000-0000-000000000000" }
      ]

      password_version = 1 # bump to apply a new server_passwords["db"].password

      # Server options, keyed by option name (scw baremetal option list)
      options = {
        "Remote Access" = { expires_at = "2027-12-31T23:59:59Z" }
      }
    }
  }

  # Installation passwords (write-only, never stored in state); use TF_VAR_server_passwords or a CI secret
  server_passwords = var.server_passwords

  # Option 1: Reference existing SSH keys by ID
  ssh_key_ids = ["00000000-0000-0000-0000-000000000000"]

  # Option 2: Create new SSH keys (attached to all servers)
  ssh_keys = {
    admin = {
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... admin@example.com"
    }
    deploy = {
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... deploy@example.com"
    }
  }

  tags = ["managed-by-terraform", "environment:production"]

  timeouts = {
    create = "2h"
    update = "1h"
    delete = "30m"
  }
}
```

More examples available in the [`examples/`](examples/) directory:

- **[Minimal](examples/minimal/)** - Simplest configuration for quick start
- **[Complete](examples/complete/)** - Full-featured production setup

## Server Configuration

Each server in the `servers` map accepts the following attributes:

| Attribute | Description | Type | Default | Required |
|-----------|-------------|------|---------|:--------:|
| `count` | Number of identical servers to create (creates name-01, name-02, etc.) | `number` | `1` | no |
| `offer` | Server offer name (e.g., "EM-A115X-SSD") | `string` | - | yes |
| `os` | Operating system name (e.g., "Ubuntu") | `string` | - | yes |
| `os_version` | Operating system version (e.g., "24.04 LTS (Noble Numbat)") | `string` | `null` | no |
| `subscription_period` | Billing period: "hourly" or "monthly" | `string` | `"hourly"` | no |
| `hostname` | Server hostname (defaults to map key, indexed if count > 1) | `string` | `null` | no |
| `description` | Server description | `string` | `""` | no |
| `tags` | Server-specific tags (merged with the module `tags`) | `list(string)` | `[]` | no |
| `ssh_key_ids` | Additional SSH key IDs for this server | `list(string)` | `[]` | no |
| `install_config_afterward` | Install configuration after server creation | `bool` | `false` | no |
| `service_user` | Service user for installation | `string` | `null` | no |
| `user` | Custom user for OS installation | `string` | `null` | no |
| `password_version` / `service_password_version` | Bump to apply a new `server_passwords[<key>]` `password` / `service_password` (see [SECURITY.md](SECURITY.md)) | `number` | `null` | no |
| `reinstall_on_config_changes` | Reinstall server when configuration changes | `bool` | `false` | no |
| `protected` | Make the Scaleway API refuse deletion of the server; `tofu destroy` fails until it is set back to `false` | `bool` | `false` | no |
| `cloud_init` | Cloud-init user data, max 127998 characters (stored in state in clear text, do not embed secrets; see [SECURITY.md](SECURITY.md)) | `string` | `null` | no |
| `partitioning` | Custom partitioning schema as a JSON document (e.g. `jsonencode(...)`) | `string` | `null` | no |
| `options` | Server options keyed by option name | `map(object)` | `{}` | no |
| `private_networks` | List of private networks to attach | `list(object)` | `[]` | no |
| `flexible_ips` | List of flexible IPs to create and attach | `list(object)` | `[]` | no |

### Private Network Configuration

Each private network in the `private_networks` list accepts:

| Attribute | Description | Type | Required |
|-----------|-------------|------|:--------:|
| `id` | Private network ID (from Scaleway VPC) | `string` | yes |
| `ipam_ip_ids` | IPAM IP IDs to use as the server's private IPs (UUID or `<zone>/<uuid>`); IPs already assigned stay if the attribute is removed later | `list(string)` | no |

> **Note:** Get private network IDs with: `scw vpc private-network list`

### Install-time and Boot-time Inputs

- `partitioning` is applied when the server is installed. Editing it on an installed server changes nothing; set it at creation, or reinstall (change `os` or use `reinstall_on_config_changes = true`).
- `cloud_init` is read at boot: a change needs a reboot to take effect. It is kept in state in clear text, so fetch secrets at boot instead of templating them in.
- `protected = true` blocks deletion by the API: set it back to `false` and apply before destroying the server.
- The `server_vlan_ids` output lists the VLAN ID of each private network attachment; `server_private_ips` lists the private IP addresses.
- `server_passwords` is a map keyed by the `servers` key (shared by every server expanded from that key). A new password is applied only when `password_version` / `service_password_version` changes. A password without its version is not rejected at plan time (ephemeral values cannot be checked); the provider decides.

### Server Options Configuration

Each entry of the `options` map is keyed by the option name and accepts:

| Attribute | Description | Type | Required |
|-----------|-------------|------|:--------:|
| `expires_at` | Option expiration date (RFC3339 format) | `string` | no |

> **Note:** List option names with: `scw baremetal option list`. The module resolves each name to its ID in the module's zone, once per distinct name.

### Flexible IP Configuration

Each flexible IP in the `flexible_ips` list accepts:

| Attribute | Description | Type | Default |
|-----------|-------------|------|---------|
| `description` | Flexible IP description | `string` | `null` |
| `tags` | Flexible IP tags (merged with the module `tags`) | `list(string)` | `[]` |
| `reverse` | Reverse DNS, a fully qualified hostname such as `api.example.com` | `string` | `null` |
| `is_ipv6` | Create IPv6 flexible IP instead of IPv4 | `bool` | `false` |

### SSH Key Configuration

Each SSH key in the `ssh_keys` map accepts:

| Attribute | Description | Type | Default | Required |
|-----------|-------------|------|---------|:--------:|
| `public_key` | SSH public key content | `string` | - | yes |
| `disabled` | Disable the SSH key | `bool` | `false` | no |

### Timeouts Configuration

| Attribute | Description | Default |
|-----------|-------------|---------|
| `create` | Timeout for server creation | `"1h"` |
| `update` | Timeout for server updates | `"1h"` |
| `delete` | Timeout for server deletion | `"1h"` |

Each value is a duration such as `30m`, `1h` or `1h30m`.

## Upgrading from v1 to v2

v2 requires the `scaleway/scaleway` provider `~> 2.89` (`tofu init -upgrade`). Resource addresses are unchanged, so no `moved` block is needed. Edit the module call as follows, then run `tofu plan`: it must show no replacement.

| v1 | v2 |
|----|----|
| `organization_id`, `project_name` | Delete both. Set `project_id` to the ID of the project `project_name` pointed to unless it is the provider's default project; otherwise servers, SSH keys and flexible IPs are replaced |
| `zone` default `"fr-par-2"` | Default is now `null` (provider default zone). Set `zone = "fr-par-2"` explicitly if you relied on the old default and the provider zone differs, otherwise servers are replaced |
| `default_tags` | Renamed `tags` |
| `default_ssh_key_ids` | Renamed `ssh_key_ids` |
| `servers[*].password`, `password_wo`, `service_password`, `service_password_wo` | Removed. Move the values to the ephemeral, sensitive input `server_passwords = { <server key> = { password, service_password } }` |
| `servers[*].password_wo_version`, `service_password_wo_version` | Renamed `password_version`, `service_password_version` |
| `servers[*].options = [{ id = "<uuid>", expires_at = ... }]` | `options = { "<option name>" = { expires_at = ... } }` (`scw baremetal option list`) |
| Output `project_id` | Removed; read the project from your own `project_id` or the provider |
| Output `server_private_ips` (VLAN IDs) | Renamed `server_vlan_ids` |
| Output `server_private_ip_addresses` | Renamed `server_private_ips` (list of IP address strings) |
| `check "plain_installation_passwords"` | Removed with the plain password inputs |

For the upgrade apply set `reinstall_on_config_changes = false` on every server that stored a plain password: the provider reinstalls on password changes, and moving a state value from `password` to `password_wo` is a change. The plain value leaves state through an in-place update; the next plan must be empty. To roll back, pin the previous tag.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_scaleway"></a> [scaleway](#requirement\_scaleway) | ~> 2.89 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_scaleway"></a> [scaleway](#provider\_scaleway) | ~> 2.89 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [scaleway_baremetal_server.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/baremetal_server) | resource |
| [scaleway_flexible_ip.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/flexible_ip) | resource |
| [scaleway_iam_ssh_key.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/iam_ssh_key) | resource |
| [scaleway_baremetal_offer.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/data-sources/baremetal_offer) | data source |
| [scaleway_baremetal_option.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/data-sources/baremetal_option) | data source |
| [scaleway_baremetal_os.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/data-sources/baremetal_os) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | ID of the Scaleway project that owns the SSH keys, servers and flexible IPs. Null uses the provider's default project; changing it replaces the resources | `string` | `null` | no |
| <a name="input_server_passwords"></a> [server\_passwords](#input\_server\_passwords) | Installation passwords per key of 'servers' (shared by every server expanded from that key), sent through write-only arguments so they never land in state. Provide them through TF\_VAR\_server\_passwords, a CI secret or a vault. A new value is applied only when the matching password\_version / service\_password\_version of the server changes | <pre>map(object({<br/>    password         = optional(string)<br/>    service_password = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_servers"></a> [servers](#input\_servers) | Map of Elastic Metal servers to create. Use 'count' to create multiple identical servers with indexed names. | <pre>map(object({<br/>    count                       = optional(number, 1)<br/>    offer                       = string<br/>    os                          = string<br/>    os_version                  = optional(string)<br/>    subscription_period         = optional(string, "hourly")<br/>    hostname                    = optional(string)<br/>    description                 = optional(string, "")<br/>    tags                        = optional(list(string), [])<br/>    ssh_key_ids                 = optional(list(string), [])<br/>    install_config_afterward    = optional(bool, false)<br/>    service_user                = optional(string)<br/>    service_password_version    = optional(number) # bump to apply a new server_passwords[<key>].service_password<br/>    user                        = optional(string)<br/>    password_version            = optional(number) # bump to apply a new server_passwords[<key>].password<br/>    reinstall_on_config_changes = optional(bool, false)<br/>    protected                   = optional(bool, false) # true makes the API refuse deletion, so destroy fails until it is set back to false<br/>    cloud_init                  = optional(string)      # user data, stored in state in clear text: do not embed secrets; applied at boot, needs a reboot to change<br/>    partitioning                = optional(string)      # JSON schema, applied on install or reinstall only<br/>    options = optional(map(object({                     # keyed by option name (scw baremetal option list)<br/>      expires_at = optional(string)<br/>    })), {})<br/>    private_networks = optional(list(object({<br/>      id          = string<br/>      ipam_ip_ids = optional(list(string)) # pins the private IPs; IPs already assigned stay if removed later<br/>    })), [])<br/>    flexible_ips = optional(list(object({<br/>      description = optional(string)<br/>      tags        = optional(list(string), [])<br/>      reverse     = optional(string)<br/>      is_ipv6     = optional(bool, false)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_ssh_key_ids"></a> [ssh\_key\_ids](#input\_ssh\_key\_ids) | Existing SSH key IDs to attach to all servers (merged with per-server ssh\_key\_ids) | `list(string)` | `[]` | no |
| <a name="input_ssh_keys"></a> [ssh\_keys](#input\_ssh\_keys) | Map of SSH keys to create and attach to all servers | <pre>map(object({<br/>    public_key = string<br/>    disabled   = optional(bool, false)<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all servers and flexible IPs (merged with their own tags) | `list(string)` | `[]` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Timeout configuration for server operations | <pre>object({<br/>    create = optional(string, "1h")<br/>    update = optional(string, "1h")<br/>    delete = optional(string, "1h")<br/>  })</pre> | `{}` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | Zone where Elastic Metal servers are deployed (e.g. fr-par-2). Null uses the provider's default zone; changing it replaces the servers | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_flexible_ip_addresses"></a> [flexible\_ip\_addresses](#output\_flexible\_ip\_addresses) | Map of server names to their flexible IP addresses |
| <a name="output_flexible_ips"></a> [flexible\_ips](#output\_flexible\_ips) | Map of all Flexible IP resources |
| <a name="output_offers"></a> [offers](#output\_offers) | Map of server names to their resolved offer details |
| <a name="output_os_images"></a> [os\_images](#output\_os\_images) | Map of server names to their resolved OS details |
| <a name="output_server_ids"></a> [server\_ids](#output\_server\_ids) | Map of server names to their IDs |
| <a name="output_server_ips"></a> [server\_ips](#output\_server\_ips) | Map of server names to their public IPv4 addresses |
| <a name="output_server_ipv6s"></a> [server\_ipv6s](#output\_server\_ipv6s) | Map of server names to their public IPv6 addresses |
| <a name="output_server_private_ips"></a> [server\_private\_ips](#output\_server\_private\_ips) | Map of server names to their private IP addresses |
| <a name="output_server_vlan_ids"></a> [server\_vlan\_ids](#output\_server\_vlan\_ids) | Map of server names to the VLAN ID of each of their private network attachments |
| <a name="output_servers"></a> [servers](#output\_servers) | Map of all Elastic Metal server resources |
| <a name="output_ssh_key_ids"></a> [ssh\_key\_ids](#output\_ssh\_key\_ids) | Map of SSH key names to their IDs |
| <a name="output_ssh_keys"></a> [ssh\_keys](#output\_ssh\_keys) | Map of all created SSH key resources |
<!-- END_TF_DOCS -->

## Contributing

Changes are planned with [OpenSpec](https://github.com/Fission-AI/OpenSpec): `openspec/specs/` is the module's current contract and [AGENTS.md](AGENTS.md) routes to the engineering standards. Behaviour changes, new inputs, outputs or resources go through a change proposal (`/openspec-propose`) before any code.

1. Open an issue describing the change.
2. Run `mise install` and `mise run spec-setup` once per machine (registers the standards stores), then create a branch from `develop`.
3. For a behaviour change, run `/openspec-propose`, implement with `/openspec-apply-change`, then `/openspec-archive-change` merges the deltas into the main specs.
4. Run `pre-commit run -a` and `mise run spec-validate`. Unit tests run with `tofu test`; new behaviour extends `tests/main.tftest.hcl`.
5. Write commit subjects that read as `CHANGELOG.md` lines: git-cliff generates the file (`mise run changelog`).

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for full details.

Copyright 2025 - This module is independently maintained and not affiliated with Scaleway.

## Disclaimer

This module is provided "as is" without warranty of any kind, express or implied. The authors and contributors are not responsible for any issues, damages, or losses arising from the use of this module. No official support is provided. Use at your own risk.

[apache]: https://opensource.org/licenses/Apache-2.0
[apache-shield]: https://img.shields.io/badge/License-Apache%202.0-blue.svg

[terraform-badge]: https://img.shields.io/badge/Terraform-%3E%3D1.11-623CE4
[terraform-url]: https://www.terraform.io

[scaleway-badge]: https://img.shields.io/badge/Scaleway%20Provider-%3E%3D2.89-4f0599
[scaleway-url]: https://registry.terraform.io/providers/scaleway/scaleway/

[release-badge]: https://img.shields.io/gitlab/v/release/leminnov/terraform/modules/scaleway-elastic-metal?include_prereleases&sort=semver
[release-url]: https://gitlab.com/leminnov/terraform/modules/scaleway-elastic-metal/-/releases
