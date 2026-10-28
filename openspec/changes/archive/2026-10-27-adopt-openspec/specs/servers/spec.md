## ADDED Requirements

### Requirement: Server definitions
The module SHALL create one `scaleway_baremetal_server` per expanded entry of `servers`, in the module's zone and project. Each entry has the required attributes `offer` and `os` (strings) and the optional attributes `count` (default 1), `os_version`, `subscription_period` (default `"hourly"`), `hostname`, `description` (default `""`), `tags` (default `[]`), `ssh_key_ids` (default `[]`), `install_config_afterward` (default `false`), `reinstall_on_config_changes` (default `false`), `options`, `private_networks`, `flexible_ips` and the installation credentials. `servers` defaults to `{}`.

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
Every key of `servers` MUST be a single alphanumeric character or start and end with an alphanumeric character and contain only alphanumerics and hyphens.

#### Scenario: Key ends with a hyphen
- **WHEN** `servers = { "web-" = {...} }`
- **THEN** the plan fails with "Server keys must be valid identifiers (alphanumeric and hyphens, not starting or ending with hyphen)."

#### Scenario: Key contains an underscore
- **WHEN** `servers = { "web_1" = {...} }`
- **THEN** the plan fails with the same error

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
The module SHALL pass `service_user`, `service_password`, `service_password_wo`, `service_password_wo_version`, `user`, `password`, `password_wo` and `password_wo_version` (all optional, no default) unchanged to the server's matching arguments. The write-only values `service_password_wo` and `password_wo` are not stored in state by the provider; changing the matching `*_wo_version` number is what applies a new write-only value. The module SHALL NOT mark the `servers` input or these attributes sensitive or ephemeral, and SHALL add no validation to them.

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
For each element of `options` (`id` required, `expires_at` optional) the server SHALL get one `options` block, and for each element of `private_networks` (`id` required) one `private_network` block.

#### Scenario: Option and private network
- **WHEN** a server sets `options = [{ id = "opt-id" }]` and `private_networks = [{ id = "pn-id" }]`
- **THEN** the server has one option block with that ID and one private network block with that ID

#### Scenario: None declared
- **WHEN** `options` and `private_networks` are unset
- **THEN** the server has no option and no private network block

### Requirement: Operation timeouts
Every server SHALL use `timeouts.create`, `timeouts.update` and `timeouts.delete` for its operation timeouts.

#### Scenario: Custom create timeout
- **WHEN** `timeouts = { create = "2h" }`
- **THEN** servers use create `2h` and update and delete `1h`
