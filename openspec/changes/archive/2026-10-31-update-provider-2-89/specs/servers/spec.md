## MODIFIED Requirements

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

## ADDED Requirements

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
