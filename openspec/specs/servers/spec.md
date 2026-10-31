# servers Specification

## Purpose
Elastic Metal servers: offer and OS lookup, count expansion, naming, credentials, options, private networks and timeouts.

## Requirements

### Requirement: Server definitions
The module SHALL create one `scaleway_baremetal_server` per expanded entry of `servers`, in the module's zone and project. Each entry has the required attributes `offer` and `os` (strings); every other attribute is optional (defaults: `count` 1, `subscription_period` `"hourly"`, `description` `""`, `install_config_afterward` and `reinstall_on_config_changes` `false`, lists `[]`). `servers` defaults to `{}`. A server that sets no `description` SHALL plan with an empty description.

#### Scenario: Minimal server
- **WHEN** `servers = { api = { offer = "EM-A610R-NVME", os = "Ubuntu" } }` and an SSH key source exists
- **THEN** one server `api` is planned with hostname `api`, hourly subscription, empty description and `install_config_afterward = false`

### Requirement: Offer and OS lookup
For each key of `servers` the module SHALL resolve the offer by `offer` name and `subscription_period` (default `hourly`) and the OS by `os` name and `os_version`, in the module's zone. Servers expanded from the same key SHALL share one lookup. The server SHALL use the resolved offer ID and the part of the resolved OS ID after the first `/`.

#### Scenario: Shared lookup for count
- **WHEN** server `web` has `count = 3`
- **THEN** one offer lookup and one OS lookup exist for `web` and `offers` and `os_images` each have the single key `web`

#### Scenario: Monthly subscription
- **WHEN** a server sets `subscription_period = "monthly"`
- **THEN** the offer is looked up with the monthly subscription period

### Requirement: Server key validation
Every key of `servers` MUST consist of alphanumerics and hyphens only and start and end with an alphanumeric character; a single character key MUST be alphanumeric.

#### Scenario: Key ends with a hyphen
- **WHEN** `servers = { "web-" = {...} }`
- **THEN** the plan fails with "Server keys must be valid identifiers (alphanumeric and hyphens, not starting or ending with hyphen)."

#### Scenario: Key contains an underscore
- **WHEN** `servers = { "web_1" = {...} }`
- **THEN** the plan fails with the same error

#### Scenario: Single character key that is not alphanumeric
- **WHEN** `servers = { "-" = {...} }` or `servers = { "_" = {...} }`
- **THEN** the plan fails with the same error

#### Scenario: Single alphanumeric character key
- **WHEN** `servers = { "a" = {...} }`
- **THEN** the key is accepted

### Requirement: Subscription period validation
`subscription_period` MUST be `"hourly"` or `"monthly"`.

#### Scenario: Unsupported period
- **WHEN** a server sets `subscription_period = "yearly"`
- **THEN** the plan fails with "subscription_period must be either 'hourly' or 'monthly'."

### Requirement: Count expansion and naming
A server entry with `count` greater than 1 SHALL expand to servers named `<key>-01`, `<key>-02`, and so on (two-digit index); with `count` 1 or unset it SHALL keep the key as its name. `count` MUST be between 1 and 100. The Scaleway server `name` and `hostname` SHALL be equal. The hostname SHALL be the `hostname` attribute (or the key when unset) with `-<NN>` appended when `count` is greater than 1, otherwise the `hostname` attribute or the key.

#### Scenario: Count of three
- **WHEN** server `web` has `count = 3`
- **THEN** servers `web-01`, `web-02` and `web-03` are planned with those hostnames

#### Scenario: Custom hostname with count
- **WHEN** server `web` has `count = 2` and `hostname = "front"`
- **THEN** the servers are keyed `web-01` and `web-02` and their hostnames are `front-01` and `front-02`

#### Scenario: Custom hostname without count
- **WHEN** server `api` has `hostname = "api-server"`
- **THEN** the server is keyed `api` and its hostname is `api-server`

#### Scenario: Count out of range
- **WHEN** a server sets `count = 0` or `count = 101`
- **THEN** the plan fails with "Server count must be between 1 and 100."

### Requirement: Descriptions and tags
With `count` greater than 1 and a non-empty `description`, each server's description SHALL be the description followed by a space and the two-digit index; otherwise it SHALL be the description unchanged. Each server's tags SHALL be `default_tags` merged with the server's `tags`, without duplicates.

#### Scenario: Indexed description
- **WHEN** server `web` has `count = 2` and `description = "Web server"`
- **THEN** the descriptions are `Web server 01` and `Web server 02`

#### Scenario: Description with a single server
- **WHEN** server `api` has `count = 1` and `description = "API"`
- **THEN** the description is `API`

#### Scenario: Tags merged
- **WHEN** `default_tags = ["prod"]` and a server sets `tags = ["web", "prod"]`
- **THEN** its tags are `prod` and `web`, each once

### Requirement: Installation credentials
The module SHALL pass the optional attributes `service_user`, `service_password`, `service_password_wo`, `service_password_wo_version`, `user`, `password`, `password_wo` and `password_wo_version` unchanged to the server's matching arguments. Changing a `*_wo_version` number is what applies a new write-only value. The module SHALL NOT mark the `servers` input sensitive or ephemeral and SHALL add no validation to these attributes.

#### Scenario: Write-only password
- **WHEN** a server sets `password_wo = "..."` and `password_wo_version = 1`
- **THEN** both are passed to the server's `password_wo` and `password_wo_version` arguments

#### Scenario: Bumping the version
- **WHEN** `password_wo_version` changes from 1 to 2 with a new `password_wo`
- **THEN** the new value is passed together with version 2

#### Scenario: Credentials not set
- **WHEN** no credential attribute is set
- **THEN** all eight arguments are null

### Requirement: Install configuration behaviour
The module SHALL pass `install_config_afterward` and `reinstall_on_config_changes` unchanged to the server.

#### Scenario: Reinstall on changes
- **WHEN** a server sets `reinstall_on_config_changes = true`
- **THEN** the server resource is planned with that argument true

### Requirement: Server options and private networks
For each element of `options` (`id` required, `expires_at` optional) the server SHALL get one `options` block, and for each element of `private_networks` (`id` required, `ipam_ip_ids` optional list of IPAM IP IDs, default `null`) one `private_network` block carrying that `id` and, only when set, those `ipam_ip_ids`. Every `ipam_ip_ids` entry MUST be a UUID, optionally prefixed by its zone or region (`<locality>/<uuid>`).

#### Scenario: Option and private network
- **WHEN** a server sets `options = [{ id = "opt-id" }]` and `private_networks = [{ id = "pn-id" }]`
- **THEN** the server has one option block with that ID and one private network block with that ID and no `ipam_ip_ids`

#### Scenario: None declared
- **WHEN** `options` and `private_networks` are unset
- **THEN** the server has no option and no private network block

#### Scenario: Pinned private IPs
- **WHEN** a private network sets `ipam_ip_ids = ["11111111-1111-1111-1111-111111111111"]`
- **THEN** the private network block carries that IPAM IP ID

#### Scenario: Malformed IPAM IP ID
- **WHEN** a private network sets `ipam_ip_ids = ["not-a-uuid"]`
- **THEN** the plan fails with "ipam_ip_ids entries must be UUIDs, optionally prefixed by a zone or region (e.g. fr-par-2/<uuid>)."

### Requirement: Operation timeouts
Every server SHALL use `timeouts.create`, `timeouts.update` and `timeouts.delete` for its operation timeouts.

#### Scenario: Custom create timeout
- **WHEN** `timeouts = { create = "2h" }`
- **THEN** servers use create `2h` and update and delete `1h`

### Requirement: Plain installation passwords are reported
A `check` block SHALL warn at plan time, naming the server keys and never the values, when any server sets the plain `password` or `service_password`, advising the `password_wo` / `service_password_wo` forms. The check MUST NOT block the plan. `SECURITY.md` SHALL list what lands in state.

#### Scenario: Plain password used
- **WHEN** server `api` sets `password = "..."`
- **THEN** the plan succeeds with a warning naming `api` and recommending `password_wo`

#### Scenario: Plain service password used
- **WHEN** server `api` sets `service_password = "..."`
- **THEN** the plan succeeds with the same warning

#### Scenario: Only write-only passwords
- **WHEN** servers set only `password_wo` and `service_password_wo`
- **THEN** no warning is emitted

### Requirement: Server protection
A server SHALL accept the optional attribute `protected` (bool, default `false`) and pass it unchanged to the server resource, which makes the Scaleway API refuse its deletion while true.

#### Scenario: Protected server
- **WHEN** a server sets `protected = true`
- **THEN** the server resource is planned with `protected = true`

#### Scenario: Not set
- **WHEN** `protected` is unset
- **THEN** the server resource is planned with `protected = false` and an existing server shows no diff

### Requirement: Cloud-init user data
A server SHALL accept the optional attribute `cloud_init` (string, default `null`) and pass it unchanged to the server's `cloud_init` argument only when set. It MUST NOT exceed 127998 characters. The value is stored in state; `SECURITY.md` SHALL list it in the "what lands in state" table and advise against embedding secrets in it.

#### Scenario: Cloud-init content
- **WHEN** a server sets `cloud_init = file("userdata.yaml")`
- **THEN** that content is passed to the server's `cloud_init` argument

#### Scenario: Not set
- **WHEN** `cloud_init` is unset
- **THEN** the argument is null and no diff appears for a server whose offer reports cloud-init data

#### Scenario: Cloud-init too long
- **WHEN** `cloud_init` has more than 127998 characters
- **THEN** the plan fails with "cloud_init must not exceed 127998 characters."

### Requirement: Custom partitioning
A server SHALL accept the optional attribute `partitioning` (string, default `null`) holding the partitioning schema as JSON, passed unchanged to the server's `partitioning` argument only when set. It MUST be valid JSON. The schema is applied when the server is installed (creation or reinstall) and is not changed in place.

#### Scenario: Partitioning schema
- **WHEN** a server sets `partitioning = jsonencode({ disks = [], filesystems = [], raids = [], zfs = { pools = [] } })`
- **THEN** that JSON is passed to the server's `partitioning` argument

#### Scenario: Not set
- **WHEN** `partitioning` is unset
- **THEN** the argument is null and the provider applies the default partitioning

#### Scenario: Partitioning is not JSON
- **WHEN** `partitioning = "disks: []"`
- **THEN** the plan fails with "partitioning must be a valid JSON document."
