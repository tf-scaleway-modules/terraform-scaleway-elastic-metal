## MODIFIED Requirements

### Requirement: Server, SSH key and default inputs
The module SHALL expose the optional inputs `servers` (map of objects, default `{}`), `ssh_keys` (map of objects, default `{}`), `default_ssh_key_ids` (list of strings, default `[]`), `default_tags` (list of strings, default `[]`) and `timeouts` (object with optional `create`, `update`, `delete` strings, each defaulting to `"1h"`, default `{}`). Each `timeouts` value MUST be a duration made of numbers with a unit of `ns`, `us`, `µs`, `ms`, `s`, `m` or `h` (for example `30m`, `1h30m`), or `0`. The attributes of `servers` are specified by the `servers` and `flexible-ips` capabilities and those of `ssh_keys` by the `ssh-keys` capability.

#### Scenario: Nothing to create
- **WHEN** only `organization_id` is set
- **THEN** no SSH key, server or flexible IP is planned and `server_ids`, `ssh_key_ids` and `flexible_ips` are empty maps

#### Scenario: Default timeouts
- **WHEN** `timeouts` is not set
- **THEN** create, update and delete timeouts of every server are `1h`

#### Scenario: Malformed timeout
- **WHEN** `timeouts = { create = "2 hours" }` or `timeouts = { delete = "30" }`
- **THEN** the plan fails with "Timeouts must be durations such as 30m, 1h or 1h30m."

### Requirement: Output shapes
`server_ips`, `server_ipv6s` and `server_private_ips` SHALL map a server name to a list of public IPv4 addresses, public IPv6 addresses and the `vlan_id` of each private network attachment (the output description says VLAN IDs, not IP addresses); `offers` and `os_images` SHALL map a key of `servers` to the resolved data source.

#### Scenario: Outputs keyed by expanded name
- **WHEN** a server definition `web` has `count = 2`
- **THEN** `server_ids`, `server_ips`, `server_ipv6s`, `server_private_ips` and `flexible_ip_addresses` are keyed `web-01` and `web-02`, while `offers` and `os_images` are keyed `web`

#### Scenario: IPv4 and IPv6 separation
- **WHEN** a server has both IPv4 and IPv6 addresses
- **THEN** `server_ips` lists only the IPv4 addresses and `server_ipv6s` only the IPv6 addresses of that server

#### Scenario: Private network output content
- **WHEN** a server is attached to one private network
- **THEN** `server_private_ips` lists for that server one element, the `vlan_id` reported by the provider for that attachment
