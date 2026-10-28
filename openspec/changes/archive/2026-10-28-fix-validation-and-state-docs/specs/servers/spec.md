## MODIFIED Requirements

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

### Requirement: Installation credentials
The module SHALL pass the optional attributes `service_user`, `service_password`, `service_password_wo`, `service_password_wo_version`, `user`, `password`, `password_wo` and `password_wo_version` unchanged to the server's matching arguments. Changing a `*_wo_version` number is what applies a new write-only value. The module SHALL NOT mark the `servers` input sensitive or ephemeral and SHALL add no validation to these attributes. The plain `password` and `service_password` are stored in state; the `*_wo` forms are not.

#### Scenario: Write-only password
- **WHEN** a server sets `password_wo = "..."` and `password_wo_version = 1`
- **THEN** both are passed to the server's `password_wo` and `password_wo_version` arguments

#### Scenario: Bumping the version
- **WHEN** `password_wo_version` changes from 1 to 2 with a new `password_wo`
- **THEN** the new value is passed together with version 2

#### Scenario: Credentials not set
- **WHEN** no credential attribute is set
- **THEN** all eight arguments are null

### Requirement: Server definitions
The module SHALL create one `scaleway_baremetal_server` per expanded entry of `servers`, in the module's zone and project. Each entry has the required attributes `offer` and `os` (strings); every other attribute is optional (defaults: `count` 1, `subscription_period` `"hourly"`, `description` `""`, `install_config_afterward` and `reinstall_on_config_changes` `false`, lists `[]`). `servers` defaults to `{}`. A server that sets no `description` SHALL plan with an empty description.

#### Scenario: Minimal server
- **WHEN** `servers = { api = { offer = "EM-A610R-NVME", os = "Ubuntu" } }` and an SSH key source exists
- **THEN** one server `api` is planned with hostname `api`, hourly subscription, empty description and `install_config_afterward = false`

## ADDED Requirements

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
