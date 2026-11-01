## MODIFIED Requirements

### Requirement: Server definitions
The module SHALL create one `scaleway_baremetal_server` per expanded entry of `servers`, in the module's zone and project. Each entry has the required attributes `offer` and `os` (strings); every other attribute is optional (defaults: `count` 1, `subscription_period` `"hourly"`, `description` `""`, `install_config_afterward` and `reinstall_on_config_changes` `false`, lists and maps empty). `servers` defaults to `{}`. A server that sets no `description` SHALL plan with an empty description.

#### Scenario: Minimal server
- **WHEN** `servers = { api = { offer = "EM-A610R-NVME", os = "Ubuntu" } }` and an SSH key source exists
- **THEN** one server `api` is planned with hostname `api`, hourly subscription, empty description and `install_config_afterward = false`

### Requirement: Descriptions and tags
With `count` greater than 1 and a non-empty `description`, each server's description SHALL be the description followed by a space and the two-digit index; otherwise it SHALL be the description unchanged. Each server's tags SHALL be the module `tags` merged with the server's `tags`, without duplicates.

#### Scenario: Indexed description
- **WHEN** server `web` has `count = 2` and `description = "Web server"`
- **THEN** the descriptions are `Web server 01` and `Web server 02`

#### Scenario: Description with a single server
- **WHEN** server `api` has `count = 1` and `description = "API"`
- **THEN** the description is `API`

#### Scenario: Tags merged
- **WHEN** `tags = ["prod"]` and a server sets `tags = ["web", "prod"]`
- **THEN** its tags are `prod` and `web`, each once

### Requirement: Installation credentials
A server SHALL accept optional `user`, `service_user` (strings), `password_version` and `service_password_version` (numbers). Passwords SHALL come only from the sensitive, ephemeral input `server_passwords` (map keyed by `servers` key with optional `password` and `service_password`, default `{}`), sent through write-only arguments and shared by every server expanded from that key. Changing a version applies a new password. No password SHALL be stored in state.

#### Scenario: Write-only password
- **WHEN** `servers = { api = { ..., password_version = 1 } }` and `server_passwords = { api = { password = "..." } }`
- **THEN** the password is sent through `password_wo` with `password_wo_version = 1` and does not appear in the plan or state

#### Scenario: Bumping the version
- **WHEN** `password_version` changes from 1 to 2 with a new password
- **THEN** the new value is sent together with version 2

#### Scenario: Credentials not set
- **WHEN** no credential attribute and no `server_passwords` entry exist
- **THEN** all password and version arguments are null

#### Scenario: Shared by count
- **WHEN** server `web` has `count = 2` and `server_passwords = { web = { password = "..." } }`
- **THEN** `web-01` and `web-02` receive the same write-only password

### Requirement: Server protection
A server SHALL accept the optional attribute `protected` (bool, default `false`) and pass it unchanged to the server resource, which makes the Scaleway API refuse its deletion while true.

#### Scenario: Protected server
- **WHEN** a server sets `protected = true`
- **THEN** the server resource is planned with `protected = true`

#### Scenario: Not set
- **WHEN** `protected` is unset
- **THEN** the server resource is planned with `protected = false` and an existing server shows no diff

## ADDED Requirements

### Requirement: Server options by name
A server SHALL accept the optional attribute `options` (map of objects keyed by option name, each with an optional `expires_at` string, default `{}`). For each key the module SHALL resolve the option ID by name in the module's zone, once per distinct name across all servers, and add one `options` block with that ID and `expires_at`.

#### Scenario: Option by name
- **WHEN** a server sets `options = { "Remote Access" = { expires_at = "2027-12-31T23:59:59Z" } }`
- **THEN** one option lookup named `Remote Access` exists and the server has one option block with the resolved ID and that expiry

#### Scenario: Shared option name
- **WHEN** two servers both set the option `Remote Access`
- **THEN** one lookup serves both servers

#### Scenario: None declared
- **WHEN** `options` is unset on every server
- **THEN** no option lookup exists and no server has an option block

### Requirement: Private network attachments
For each element of a server's `private_networks` (list; `id` required, `ipam_ip_ids` optional list of IPAM IP IDs, default `null`) the server SHALL get one `private_network` block carrying that `id` and, only when set, those `ipam_ip_ids`. Every `ipam_ip_ids` entry MUST be a UUID, optionally prefixed by its zone or region (`<locality>/<uuid>`).

#### Scenario: Private network
- **WHEN** a server sets `private_networks = [{ id = "pn-id" }]`
- **THEN** the server has one private network block with that ID and no `ipam_ip_ids`

#### Scenario: None declared
- **WHEN** `private_networks` is unset
- **THEN** the server has no private network block

#### Scenario: Pinned private IPs
- **WHEN** a private network sets `ipam_ip_ids = ["11111111-1111-1111-1111-111111111111"]`
- **THEN** the private network block carries that IPAM IP ID

#### Scenario: Malformed IPAM IP ID
- **WHEN** a private network sets `ipam_ip_ids = ["not-a-uuid"]`
- **THEN** the plan fails with "ipam_ip_ids entries must be UUIDs, optionally prefixed by a zone or region (e.g. fr-par-2/<uuid>)."

## REMOVED Requirements

### Requirement: Server options and private networks
**Reason**: Options are now selected by name (`Server options by name`) and private network attachments are specified on their own (`Private network attachments`).
**Migration**: Replace each `options = [{ id = "<uuid>", expires_at = ... }]` element by `options = { "<option name>" = { expires_at = ... } }`; `private_networks` is unchanged.

### Requirement: Plain installation passwords are reported
**Reason**: The plain `password` and `service_password` attributes no longer exist, so there is nothing to warn about; installation passwords can only be write-only.
**Migration**: Move `password`, `password_wo`, `service_password` and `service_password_wo` values to `server_passwords`, and rename `password_wo_version` / `service_password_wo_version` to `password_version` / `service_password_version`.
