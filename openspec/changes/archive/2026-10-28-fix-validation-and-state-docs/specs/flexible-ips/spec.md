## MODIFIED Requirements

### Requirement: Flexible IP outputs
`flexible_ips` SHALL expose the flexible IP resources keyed as above, and `flexible_ip_addresses` SHALL map each server name to the addresses of the flexible IPs attached to that server, never those of another server whose name merely extends it.

#### Scenario: Addresses per server
- **WHEN** server `api` has two flexible IPs
- **THEN** `flexible_ip_addresses["api"]` lists both addresses

#### Scenario: Server without flexible IPs
- **WHEN** a server has no flexible IP
- **THEN** `flexible_ip_addresses` maps its name to an empty list

#### Scenario: Server name extends another
- **WHEN** servers `web` and `web-fip-x` both exist and only `web-fip-x` has a flexible IP
- **THEN** `flexible_ip_addresses["web"]` is an empty list
