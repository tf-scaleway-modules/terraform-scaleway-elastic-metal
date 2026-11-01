# module-contract Specification

## Purpose
Tooling and provider constraints, inputs, validations and outputs of the module.

## Requirements

### Requirement: Supported tooling and providers
The module SHALL require OpenTofu/Terraform `>= 1.11.0` and the `scaleway/scaleway` provider `~> 2.89`, and SHALL declare no other provider.

#### Scenario: Version constraints
- **WHEN** a consumer runs `tofu init` with a version older than 1.11.0
- **THEN** initialization fails on the `required_version` constraint

#### Scenario: Provider floor
- **WHEN** a consumer pins the `scaleway` provider to 2.88.0
- **THEN** initialization fails on the provider constraint

### Requirement: No provider or backend configuration
The module MUST NOT contain `provider {}` or `backend {}` blocks; the caller SHALL configure the `scaleway` provider.

#### Scenario: Provider configured by the caller
- **WHEN** the module is called with a `scaleway` provider configured in the root module
- **THEN** the module's resources and data sources use that provider and the module sets no credentials

### Requirement: Server, SSH key and default inputs
The module SHALL expose the optional inputs `servers` (map of objects, default `{}`), `ssh_keys` (map of objects, default `{}`), `ssh_key_ids` (list of strings, default `[]`), `tags` (list of strings, default `[]`) and `timeouts` (object with optional `create`, `update`, `delete` strings, each defaulting to `"1h"`, default `{}`). The attributes of `servers` are specified by the `servers` and `flexible-ips` capabilities and those of `ssh_keys` by `ssh-keys`.

#### Scenario: Nothing to create
- **WHEN** no input is set
- **THEN** no SSH key, server or flexible IP is planned and `server_ids`, `ssh_key_ids` and `flexible_ips` are empty maps

#### Scenario: Default timeouts
- **WHEN** `timeouts` is not set
- **THEN** create, update and delete timeouts of every server are `1h`

### Requirement: Timeouts are durations
Each `timeouts` value MUST be a duration made of numbers with a unit of `ns`, `us`, `µs`, `ms`, `s`, `m` or `h` (for example `30m`, `1h30m`), or `0`.

#### Scenario: Malformed timeout
- **WHEN** `timeouts = { create = "2 hours" }` or `timeouts = { delete = "30" }`
- **THEN** the plan fails with "Timeouts must be durations such as 30m, 1h or 1h30m."

### Requirement: Outputs
The module SHALL expose the outputs `servers`, `server_ids`, `server_ips`, `server_ipv6s`, `server_vlan_ids`, `server_private_ips`, `offers`, `os_images`, `flexible_ips`, `flexible_ip_addresses`, `ssh_keys` and `ssh_key_ids`. Only `servers` (all server resources) and `ssh_keys` (all created SSH key resources) SHALL be marked sensitive.

#### Scenario: Sensitive outputs
- **WHEN** the module is applied
- **THEN** `servers` and `ssh_keys` are redacted in CLI output while `server_ids`, `server_ips` and `ssh_key_ids` are shown

### Requirement: Output shapes
`server_ips`, `server_ipv6s`, `server_vlan_ids` and `server_private_ips` SHALL map a server name to a list of public IPv4 addresses, public IPv6 addresses, the `vlan` ID of each private network attachment and the private IP addresses of the server; `offers` and `os_images` SHALL map a key of `servers` to the resolved data source.

#### Scenario: Outputs keyed by expanded name
- **WHEN** a server definition `web` has `count = 2`
- **THEN** `server_ids`, `server_ips`, `server_ipv6s`, `server_vlan_ids`, `server_private_ips` and `flexible_ip_addresses` are keyed `web-01` and `web-02`, while `offers` and `os_images` are keyed `web`

#### Scenario: IPv4 and IPv6 separation
- **WHEN** a server has both IPv4 and IPv6 addresses
- **THEN** `server_ips` lists only the IPv4 addresses and `server_ipv6s` only the IPv6 addresses of that server

#### Scenario: Private network output content
- **WHEN** a server is attached to one private network
- **THEN** `server_vlan_ids` lists for that server one element, the `vlan` ID reported by the provider, and the plan does not fail

#### Scenario: Private IP addresses
- **WHEN** a server is attached to a private network and has been assigned private IPs
- **THEN** `server_private_ips` lists those addresses for that server, and an empty list when it has none

### Requirement: Project input
The module SHALL expose `project_id` (string, default `null`). When `null` the SSH keys, servers and flexible IPs use the provider's default project; otherwise they use that project. The module SHALL NOT look the project up by name. `project_id`, when set, MUST be a lowercase UUID.

#### Scenario: Default project
- **WHEN** `project_id` is not set
- **THEN** every resource is planned with no explicit project and no `scaleway_account_project` data source exists

#### Scenario: Explicit project
- **WHEN** `project_id = "11111111-1111-1111-1111-111111111111"`
- **THEN** the SSH keys, servers and flexible IPs are planned in that project

#### Scenario: Project ID is not a UUID
- **WHEN** `project_id = "default"`
- **THEN** the plan fails with "project_id must be a valid UUID."

### Requirement: Zone input
The module SHALL expose `zone` (string, default `null`). When `null` the offer, OS and option lookups, servers and flexible IPs use the provider's default zone. A set `zone` MUST match the format `xx-xxx-N`.

#### Scenario: Zone has the wrong format
- **WHEN** `zone = "paris"`
- **THEN** the plan fails with "Zone must be in format: xx-xxx-N (e.g., fr-par-2)."

#### Scenario: Default zone
- **WHEN** `zone` is not set
- **THEN** no zone is passed to the resources and lookups

### Requirement: SSH key IDs are validated
Every entry of `ssh_key_ids` MUST be a lowercase UUID.

#### Scenario: SSH key ID is not a UUID
- **WHEN** `ssh_key_ids = ["abc"]`
- **THEN** the plan fails with "All SSH key IDs must be valid UUIDs."
