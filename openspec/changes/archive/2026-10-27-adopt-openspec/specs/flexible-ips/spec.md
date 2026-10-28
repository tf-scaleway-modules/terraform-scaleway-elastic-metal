## ADDED Requirements

### Requirement: Flexible IPs per server
For each element of a server's `flexible_ips` list (default `[]`) the module SHALL create one `scaleway_flexible_ip` in the module's zone and project, attached to that expanded server, with the element's `description` (optional), `reverse` (optional) and `is_ipv6` (optional, default `false`). The resource key SHALL be `<expanded server name>-fip-<index>` where the index starts at 0.

#### Scenario: One flexible IP
- **WHEN** server `api` sets `flexible_ips = [{ description = "failover" }]`
- **THEN** one flexible IP keyed `api-fip-0` is planned, attached to `api`, IPv4 (`is_ipv6 = false`)

#### Scenario: IPv6 flexible IP with reverse
- **WHEN** an element sets `is_ipv6 = true` and `reverse = "api.example.com"`
- **THEN** the flexible IP is IPv6 and carries that reverse

#### Scenario: Server expanded by count
- **WHEN** server `web` has `count = 2` and one flexible IP definition
- **THEN** two flexible IPs keyed `web-01-fip-0` and `web-02-fip-0` are planned, one per server

#### Scenario: No flexible IPs
- **WHEN** no server sets `flexible_ips`
- **THEN** no flexible IP is planned and `flexible_ips` is an empty map

### Requirement: Flexible IP tags
Each flexible IP SHALL carry `default_tags` merged with its own `tags` (optional, default `[]`), without duplicates.

#### Scenario: Tags merged
- **WHEN** `default_tags = ["prod"]` and a flexible IP sets `tags = ["prod", "edge"]`
- **THEN** its tags are `prod` and `edge`, each once

### Requirement: Flexible IP outputs
`flexible_ips` SHALL expose the flexible IP resources keyed as above, and `flexible_ip_addresses` SHALL map each server name to the addresses of the flexible IPs whose key starts with `<server name>-fip-`.

#### Scenario: Addresses per server
- **WHEN** server `api` has two flexible IPs
- **THEN** `flexible_ip_addresses["api"]` lists both addresses

#### Scenario: Server without flexible IPs
- **WHEN** a server has no flexible IP
- **THEN** `flexible_ip_addresses` maps its name to an empty list
