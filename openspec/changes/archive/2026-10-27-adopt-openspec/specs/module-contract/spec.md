## ADDED Requirements

### Requirement: Supported tooling and providers
The module SHALL require OpenTofu/Terraform `>= 1.11.0` and the `scaleway/scaleway` provider `~> 2.86`, and SHALL declare no other provider.

#### Scenario: Version constraints
- **WHEN** a consumer runs `tofu init` with a version older than 1.11.0
- **THEN** initialization fails on the `required_version` constraint

### Requirement: No provider or backend configuration
The module MUST NOT contain `provider {}` or `backend {}` blocks; the caller SHALL configure the `scaleway` provider.

#### Scenario: Provider configured by the caller
- **WHEN** the module is called with a `scaleway` provider configured in the root module
- **THEN** the module's resources and data sources use that provider and the module sets no credentials

### Requirement: Scope and organization inputs
The module SHALL expose `organization_id` (string, required), `project_name` (string, default `"default"`) and `zone` (string, default `"fr-par-2"`). `organization_id` MUST be a lowercase UUID and `zone` MUST match the format `xx-xxx-N`. The module SHALL resolve the project from `project_name` and `organization_id` and use it for the SSH keys, servers and flexible IPs.

#### Scenario: Organization ID is not a UUID
- **WHEN** `organization_id = "my-org"`
- **THEN** the plan fails with "Organization ID must be a valid UUID."

#### Scenario: Zone has the wrong format
- **WHEN** `zone = "paris"`
- **THEN** the plan fails with "Zone must be in format: xx-xxx-N (e.g., fr-par-2)."

#### Scenario: Defaults
- **WHEN** only `organization_id` is set
- **THEN** the project named `default` is looked up and resources target zone `fr-par-2`

### Requirement: Server, SSH key and default inputs
The module SHALL expose the optional inputs `servers` (map of objects, default `{}`), `ssh_keys` (map of objects, default `{}`), `default_ssh_key_ids` (list of strings, default `[]`), `default_tags` (list of strings, default `[]`) and `timeouts` (object with optional `create`, `update`, `delete` strings, each defaulting to `"1h"`, default `{}`). The attributes of `servers` are specified by the `servers` and `flexible-ips` capabilities and those of `ssh_keys` by the `ssh-keys` capability.

#### Scenario: Nothing to create
- **WHEN** only `organization_id` is set
- **THEN** no SSH key, server or flexible IP is planned and `server_ids`, `ssh_key_ids` and `flexible_ips` are empty maps

#### Scenario: Default timeouts
- **WHEN** `timeouts` is not set
- **THEN** create, update and delete timeouts of every server are `1h`

### Requirement: Default SSH key IDs are validated
Every entry of `default_ssh_key_ids` MUST be a lowercase UUID.

#### Scenario: Default SSH key ID is not a UUID
- **WHEN** `default_ssh_key_ids = ["abc"]`
- **THEN** the plan fails with "All SSH key IDs must be valid UUIDs."

### Requirement: Outputs
The module SHALL expose these outputs: `project_id` (project ID), `servers` (all server resources, sensitive), `server_ids` (server name to ID), `server_ips` (server name to list of public IPv4 addresses), `server_ipv6s` (server name to list of public IPv6 addresses), `server_private_ips` (server name to list with the `vlan_id` of each private network attachment), `offers` (key of `servers` to the resolved offer data source), `os_images` (key of `servers` to the resolved OS data source), `flexible_ips` (all flexible IP resources), `flexible_ip_addresses` (server name to list of its flexible IP addresses), `ssh_keys` (all created SSH key resources, sensitive) and `ssh_key_ids` (SSH key name to ID). Only `servers` and `ssh_keys` SHALL be marked sensitive.

#### Scenario: Sensitive outputs
- **WHEN** the module is applied
- **THEN** `servers` and `ssh_keys` are redacted in CLI output while `server_ids`, `server_ips` and `ssh_key_ids` are shown

#### Scenario: Outputs keyed by expanded name
- **WHEN** a server definition `web` has `count = 2`
- **THEN** `server_ids`, `server_ips`, `server_ipv6s`, `server_private_ips` and `flexible_ip_addresses` are keyed `web-01` and `web-02`, while `offers` and `os_images` are keyed `web`

#### Scenario: IPv4 and IPv6 separation
- **WHEN** a server has both IPv4 and IPv6 addresses
- **THEN** `server_ips` lists only the IPv4 addresses and `server_ipv6s` only the IPv6 addresses of that server

#### Scenario: Private network output content
- **WHEN** a server is attached to one private network
- **THEN** `server_private_ips` lists for that server one element, the `vlan_id` reported by the provider for that attachment
