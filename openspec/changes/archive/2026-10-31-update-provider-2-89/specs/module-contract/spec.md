## MODIFIED Requirements

### Requirement: Outputs
The module SHALL expose the outputs `project_id`, `servers`, `server_ids`, `server_ips`, `server_ipv6s`, `server_private_ips`, `server_private_ip_addresses`, `offers`, `os_images`, `flexible_ips`, `flexible_ip_addresses`, `ssh_keys` and `ssh_key_ids`. Only `servers` (all server resources) and `ssh_keys` (all created SSH key resources) SHALL be marked sensitive.

#### Scenario: Sensitive outputs
- **WHEN** the module is applied
- **THEN** `servers` and `ssh_keys` are redacted in CLI output while `server_ids`, `server_ips` and `ssh_key_ids` are shown

### Requirement: Output shapes
`server_ips`, `server_ipv6s`, `server_private_ips` and `server_private_ip_addresses` SHALL map a server name to a list of public IPv4 addresses, public IPv6 addresses, the `vlan` ID of each private network attachment (read from the attachment's `vlan` attribute) and the private IP addresses of the server; `offers` and `os_images` SHALL map a key of `servers` to the resolved data source.

#### Scenario: Outputs keyed by expanded name
- **WHEN** a server definition `web` has `count = 2`
- **THEN** `server_ids`, `server_ips`, `server_ipv6s`, `server_private_ips`, `server_private_ip_addresses` and `flexible_ip_addresses` are keyed `web-01` and `web-02`, while `offers` and `os_images` are keyed `web`

#### Scenario: IPv4 and IPv6 separation
- **WHEN** a server has both IPv4 and IPv6 addresses
- **THEN** `server_ips` lists only the IPv4 addresses and `server_ipv6s` only the IPv6 addresses of that server

#### Scenario: Private network output content
- **WHEN** a server is attached to one private network
- **THEN** `server_private_ips` lists for that server one element, the `vlan` ID reported by the provider for that attachment, and the plan does not fail

#### Scenario: Private IP addresses
- **WHEN** a server is attached to a private network and has been assigned private IPs
- **THEN** `server_private_ip_addresses` lists those addresses for that server, and an empty list when the server has none
