# Scaleway Elastic Metal Terraform Module

[![Apache 2.0][apache-shield]][apache]
[![Terraform][terraform-badge]][terraform-url]
[![Scaleway Provider][scaleway-badge]][scaleway-url]
[![Latest Release][release-badge]][release-url]

A production-ready Terraform module for creating and managing **Scaleway Elastic Metal** (bare metal) servers with support for multiple instances, flexible IPs, SSH key management, and private networks.

## Features

- **Multiple Servers** - Deploy and manage multiple Elastic Metal servers with a single module call
- **Flexible IPs** - Attach multiple IPv4/IPv6 flexible IPs per server for failover scenarios
- **SSH Key Management** - Create new SSH keys or reference existing ones
- **Private Networks** - Connect servers to Scaleway VPC private networks
- **Server Options** - Configure additional server options with expiration dates
- **Configurable Timeouts** - Customize create/update/delete operation timeouts
- **Tag Inheritance** - Default tags automatically merged with per-server tags

## Usage

> **Note:** To list available Elastic Metal offers in your zone, run:
> ```bash
> scw baremetal offer list zone=fr-par-2
> ```

### Minimal Example

```hcl
module "elastic_metal" {
  source = "path/to/module"

  organization_id = "00000000-0000-0000-0000-000000000000"
  project_name    = "default"
  zone            = "fr-par-2"

  servers = {
    web-server = {
      offer = "EM-A210R-HDD"  # Use: scw baremetal offer list
      os    = "Ubuntu"
    }
  }

  default_ssh_key_ids = ["00000000-0000-0000-0000-000000000000"]
}
```

### Complete Example

```hcl
module "elastic_metal" {
  source = "path/to/module"

  organization_id = "00000000-0000-0000-0000-000000000000"
  project_name    = "my-project"
  zone            = "fr-par-2"

  servers = {
    web-01 = {
      offer       = "EM-A210R-HDD"
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
  default_ssh_key_ids = ["00000000-0000-0000-0000-000000000000"]

  # Option 2: Create new SSH keys (attached to all servers)
  ssh_keys = {
    admin = {
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... admin@example.com"
    }
    deploy = {
      public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... deploy@example.com"
    }
  }

  default_tags = ["managed-by-terraform", "environment:production"]

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
| `offer` | Server offer name (e.g., "EM-A115X-SSD") | `string` | - | yes |
| `os` | Operating system name (e.g., "Ubuntu") | `string` | - | yes |
| `hostname` | Server hostname (defaults to map key) | `string` | `null` | no |
| `description` | Server description | `string` | `""` | no |
| `tags` | Server-specific tags (merged with default_tags) | `list(string)` | `[]` | no |
| `ssh_key_ids` | Additional SSH key IDs for this server | `list(string)` | `[]` | no |
| `install_config_afterward` | Install configuration after server creation | `bool` | `false` | no |
| `service_user` | Service user for installation | `string` | `null` | no |
| `service_password` | Service password for installation | `string` | `null` | no |
| `user` | Custom user for OS installation | `string` | `null` | no |
| `password` | Custom password for OS installation | `string` | `null` | no |
| `reinstall_on_config_changes` | Reinstall server when configuration changes | `bool` | `false` | no |
| `options` | List of server options | `list(object)` | `[]` | no |
| `private_networks` | List of private networks to attach | `list(object)` | `[]` | no |
| `flexible_ips` | List of flexible IPs to create and attach | `list(object)` | `[]` | no |

### Flexible IP Configuration

Each flexible IP in the `flexible_ips` list accepts:

| Attribute | Description | Type | Default |
|-----------|-------------|------|---------|
| `description` | Flexible IP description | `string` | `null` |
| `tags` | Flexible IP tags (merged with default_tags) | `list(string)` | `[]` |
| `reverse` | Reverse DNS hostname | `string` | `null` |
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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.7 |
| <a name="requirement_scaleway"></a> [scaleway](#requirement\_scaleway) | ~> 2.64 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_scaleway"></a> [scaleway](#provider\_scaleway) | 2.65.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [scaleway_baremetal_server.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/baremetal_server) | resource |
| [scaleway_flexible_ip.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/flexible_ip) | resource |
| [scaleway_iam_ssh_key.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/iam_ssh_key) | resource |
| [scaleway_account_project.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/data-sources/account_project) | data source |
| [scaleway_baremetal_offer.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/data-sources/baremetal_offer) | data source |
| [scaleway_baremetal_os.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/data-sources/baremetal_os) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_default_ssh_key_ids"></a> [default\_ssh\_key\_ids](#input\_default\_ssh\_key\_ids) | Default list of existing SSH key IDs to attach to all servers (merged with per-server ssh\_key\_ids) | `list(string)` | `[]` | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default tags to apply to all servers (merged with per-server tags) | `list(string)` | `[]` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | Scaleway organization ID | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the Scaleway project | `string` | `"default"` | no |
| <a name="input_servers"></a> [servers](#input\_servers) | Map of Elastic Metal servers to create | <pre>map(object({<br/>    offer                       = string<br/>    os                          = string<br/>    hostname                    = optional(string)<br/>    description                 = optional(string, "")<br/>    tags                        = optional(list(string), [])<br/>    ssh_key_ids                 = optional(list(string), [])<br/>    install_config_afterward    = optional(bool, false)<br/>    service_user                = optional(string)<br/>    service_password            = optional(string)<br/>    user                        = optional(string)<br/>    password                    = optional(string)<br/>    reinstall_on_config_changes = optional(bool, false)<br/>    options = optional(list(object({<br/>      id         = string<br/>      expires_at = optional(string)<br/>    })), [])<br/>    private_networks = optional(list(object({<br/>      id = string<br/>    })), [])<br/>    flexible_ips = optional(list(object({<br/>      description = optional(string)<br/>      tags        = optional(list(string), [])<br/>      reverse     = optional(string)<br/>      is_ipv6     = optional(bool, false)<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_ssh_keys"></a> [ssh\_keys](#input\_ssh\_keys) | Map of SSH keys to create and attach to all servers | <pre>map(object({<br/>    public_key = string<br/>    disabled   = optional(bool, false)<br/>  }))</pre> | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Timeout configuration for server operations | <pre>object({<br/>    create = optional(string, "1h")<br/>    update = optional(string, "1h")<br/>    delete = optional(string, "1h")<br/>  })</pre> | `{}` | no |
| <a name="input_zone"></a> [zone](#input\_zone) | Zone where Elastic Metal servers will be deployed | `string` | `"fr-par-2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_flexible_ip_addresses"></a> [flexible\_ip\_addresses](#output\_flexible\_ip\_addresses) | Map of server names to their flexible IP addresses |
| <a name="output_flexible_ips"></a> [flexible\_ips](#output\_flexible\_ips) | Map of all Flexible IP resources |
| <a name="output_offers"></a> [offers](#output\_offers) | Map of server names to their resolved offer details |
| <a name="output_project_id"></a> [project\_id](#output\_project\_id) | The Scaleway project ID |
| <a name="output_server_ids"></a> [server\_ids](#output\_server\_ids) | Map of server names to their IDs |
| <a name="output_server_ips"></a> [server\_ips](#output\_server\_ips) | Map of server names to their public IPv4 addresses |
| <a name="output_server_ipv6s"></a> [server\_ipv6s](#output\_server\_ipv6s) | Map of server names to their public IPv6 addresses |
| <a name="output_server_private_ips"></a> [server\_private\_ips](#output\_server\_private\_ips) | Map of server names to their private network IPs |
| <a name="output_servers"></a> [servers](#output\_servers) | Map of all Elastic Metal server resources |
| <a name="output_ssh_key_ids"></a> [ssh\_key\_ids](#output\_ssh\_key\_ids) | Map of SSH key names to their IDs |
| <a name="output_ssh_keys"></a> [ssh\_keys](#output\_ssh\_keys) | Map of all created SSH key resources |
<!-- END_TF_DOCS -->

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for full details.

Copyright 2025 - This module is independently maintained and not affiliated with Scaleway.

## Disclaimer

This module is provided "as is" without warranty of any kind, express or implied. The authors and contributors are not responsible for any issues, damages, or losses arising from the use of this module. No official support is provided. Use at your own risk.

[apache]: https://opensource.org/licenses/Apache-2.0
[apache-shield]: https://img.shields.io/badge/License-Apache%202.0-blue.svg

[terraform-badge]: https://img.shields.io/badge/Terraform-%3E%3D1.10-623CE4
[terraform-url]: https://www.terraform.io

[scaleway-badge]: https://img.shields.io/badge/Scaleway%20Provider-%3E%3D2.63-4f0599
[scaleway-url]: https://registry.terraform.io/providers/scaleway/scaleway/

[release-badge]: https://img.shields.io/gitlab/v/release/leminnov/terraform/modules/scaleway-elastic-metal?include_prereleases&sort=semver
[release-url]: https://gitlab.com/leminnov/terraform/modules/scaleway-elastic-metal/-/releases
