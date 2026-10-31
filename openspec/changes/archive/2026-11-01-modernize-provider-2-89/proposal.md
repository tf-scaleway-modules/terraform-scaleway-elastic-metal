## Why

The module is at v1.3.0 with `scaleway/scaleway ~> 2.86`. Provider 2.89.0 (2026-10-27) is the latest version on the
Terraform and OpenTofu registries (v2.90.0 is tagged on GitHub but unpublished; `~> 2.89` accepts it once
published, and its only module-relevant item is a computed `srn` on the ephemeral `scaleway_iam_api_key`, which
this module does not use). A major release is explicitly allowed, so this change does three things the archived
`update-provider-2-89` change could not: raise the floor to `~> 2.89`, align the module with the cross-module
conventions (single optional `project_id`, `null` = provider default location, `tags`, ephemeral secrets), and
simplify the code (dual password inputs, `coalesce` on values that `optional()` already defaults, a two-stage
local that copies every server attribute).

Gap analysis against the 2.89.0 schema (`/tmp/scw-schema/schema-2.89.0.json`): `scaleway_baremetal_server`,
`scaleway_flexible_ip` and `scaleway_iam_ssh_key` have **no argument the module could still adopt** except
resolving options by name (data source `scaleway_baremetal_option`, present long before 2.86). Every writable
argument of the three managed resources is already exposed, including `private_network.ipam_ip_ids`,
`protected`, `cloud_init`, `partitioning`, `password_wo` and `service_password_wo`. `reinstall_on_ssh_key_changes`
named in the provider's `ssh_key_ids` description does not exist in the 2.89.0 schema, so it is not adopted.
The provider floor therefore rises for policy reasons (a floor equal to the latest version is the repository's
convention), not because a 2.87 to 2.89 argument is needed.

## What Changes

### Adopted features

| # | Item | Resource / argument | Provider version | Class |
|---|------|---------------------|------------------|-------|
| 1 | Reference options by **name**: `servers[*].options` becomes a map keyed by option name, resolved to the option ID | `data.scaleway_baremetal_option` (`name` to `option_id`), `options.id` | data source exists before 2.86 (deferred in `update-provider-2-89` only to avoid widening the contract) | feature (breaking input shape) |
| 2 | Write-only installation passwords through a new ephemeral input `server_passwords` | `password_wo`, `service_password_wo` (+ `_wo_version`) | 2.86 or earlier (in schema 2.89.0) | security |
| 3 | `reverse` validated as a hostname so a bad reverse DNS fails at plan, not at apply | `scaleway_flexible_ip.reverse` | in 2.89.0 | validation |
| 4 | `server_vlan_ids` output (VLAN ID per private network attachment) with an honest name | `private_network.vlan` | in 2.89.0 | output rename |

### Breaking changes

| # | Change | Consumer edit |
|---|--------|---------------|
| 1 | `scaleway/scaleway ~> 2.89` (was `~> 2.86`) | Allow provider 2.89+ (`tofu init -upgrade`) |
| 2 | `organization_id` (required) and `project_name` (default `"default"`) removed; new optional `project_id` (string, UUID, default `null` = provider default project). `data.scaleway_account_project` removed | Delete both inputs. If the old `project_name` was not the provider's default project, set `project_id` to its ID, otherwise servers, SSH keys and flexible IPs are replaced (project is ForceNew) |
| 3 | `zone` default `"fr-par-2"` becomes `null` (provider default zone) | Set `zone = "fr-par-2"` explicitly if the provider zone differs, otherwise servers are replaced |
| 4 | `default_tags` renamed `tags` | Rename the input |
| 5 | `default_ssh_key_ids` renamed `ssh_key_ids` | Rename the input |
| 6 | `servers[*].password`, `password_wo`, `service_password`, `service_password_wo` removed; `password_wo_version` / `service_password_wo_version` renamed `password_version` / `service_password_version`; secrets move to the ephemeral, sensitive input `server_passwords = { <server key> = { password, service_password } }` | Move each value to `server_passwords`, rename the version attributes. Set `reinstall_on_config_changes = false` for the upgrade apply: the provider reinstalls on password changes and a state value moving from `password` to `password_wo` is a change |
| 7 | `servers[*].options` changes from `list(object({ id, expires_at }))` to `map(object({ expires_at }))` keyed by option name | Replace `{ id = "<uuid>", ... }` by `"<option name>" = { ... }` (`scw baremetal option list`) |
| 8 | Output `project_id` removed | Read the project from your own `project_id` or the provider |
| 9 | Output `server_private_ips` (VLAN IDs) renamed `server_vlan_ids`; output `server_private_ip_addresses` renamed `server_private_ips` | Rename both references; note `server_private_ips` now holds IP addresses (list of strings) |
| 10 | `check "plain_installation_passwords"` removed (its inputs no longer exist) | None |

Resource addresses are unchanged (`scaleway_baremetal_server.this[<key>]`, `scaleway_iam_ssh_key.this[<key>]`,
`scaleway_flexible_ip.this["<server>-fip-<index>"]`), so no `moved` block is needed.

### Simplifications

| # | Simplification | Reason |
|---|----------------|--------|
| 1 | `local.expanded_servers` + `local.servers` merged into one local that keeps the server's `config` object instead of copying 30 attributes | `quality-simplicity`: the copy only renamed fields |
| 2 | Remove `coalesce(x, default)` on attributes declared `optional(type, default)` (a `null` already takes the default) in `locals.tf`, `data.tf` and the validations | Dead code |
| 3 | Remove the project data source and the `organization_id` validation | Replaced by `project_id` |
| 4 | Remove the plain-password check and four password attributes | Plain form stored secrets in state |
| 5 | `flexible_ip` tag merge computed once per server instead of re-derived in the flattening local | Single merge point (`tags`) |
| 6 | Server resource reads `each.value.config.<attr>` directly | Removes the field-by-field copy |

### Deferred / Rejected

| Item | Decision and reason |
|------|---------------------|
| `scaleway_flexible_ip_mac_address` (virtual MAC) | Rejected (new reason): only hypervisor-on-bare-metal setups need it and it requires a vMAC server option; speculative (`quality-simplicity`). It was deferred as "no ask yet" and still has none |
| `data.scaleway_baremetal_partition_schema` (swap, `ext_4_mountpoint`, `extra_partition` to JSON) | Rejected: a second way to set the same argument is a dual input; the `partitioning` JSON string covers every layout and the three toggles only describe the default layout |
| `data.scaleway_account_project.srn`, `scaleway_iam_ssh_key.srn`, `scaleway_flexible_ip.srn` | Rejected: no consumer; `terraform-outputs` forbids outputting every attribute |
| Flexible IPs keyed by label instead of index (`web-fip-0`) | Rejected: changing the key replaces every flexible IP and loses its public address; a `moved` block cannot map generated keys. Reordering the list remains the documented hazard |
| Drop the `count` attribute of `servers` | Rejected: the `-01` naming and shared lookups are the module's value; addresses must not change |
| Resource-name prefix input `name` | Not applicable: the module derives names from map keys, not from a prefix |
| `region` | Not applicable: every resource is zonal or global |
| `include_disabled` on the offer lookup | Rejected: would let a plan select an unorderable offer |
| `ssh_keys` / `servers` outputs sensitivity | Unchanged: `servers` can carry `cloud_init` secrets |
| Make `servers` ephemeral/sensitive | Impossible: keys drive `for_each` (same as `fix-validation-and-state-docs`). `cloud_init` stays in state, documented in `SECURITY.md` |
| `server_private_ip_addresses` kept next to the renamed output | Rejected: two names for IPs |

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `module-contract`: provider floor `~> 2.89`, `project_id`/`zone`/`tags`/`ssh_key_ids`/`server_passwords` inputs, `organization_id`/`project_name` removed, outputs renamed or removed
- `servers`: ephemeral installation passwords, options by name, plain password check removed, tags input
- `ssh-keys`: `project_id`, `ssh_key_ids` rename, precondition message
- `flexible-ips`: `project_id`, `tags` input, reverse DNS validation

## Semver

**Major** (`terraform-versioning`): v1.3.0 to v2.0.0. Inputs and outputs whose type, default or meaning changes:

- Removed: `organization_id`, `project_name`, `servers[*].password`, `password_wo`, `service_password`, `service_password_wo`, output `project_id`, `check "plain_installation_passwords"`.
- Renamed: `default_tags` to `tags`, `default_ssh_key_ids` to `ssh_key_ids`, `password_wo_version` / `service_password_wo_version` to `password_version` / `service_password_version`, output `server_private_ips` to `server_vlan_ids`, output `server_private_ip_addresses` to `server_private_ips` (type: list of numbers becomes list of strings).
- Type changed: `servers[*].options` (list of objects to map of objects).
- Default changed: `zone` (`"fr-par-2"` to `null`).
- Added: `project_id`, `server_passwords` (sensitive, ephemeral), validation on `servers[*].flexible_ips[*].reverse`.

## State

Resource addresses are unchanged. What lands in state: SSH public keys and server attributes as before;
`cloud_init` in clear text when set (no write-only form in the provider; `SECURITY.md` keeps the row). After
the change **no installation password lands in state**: `server_passwords` is sensitive and ephemeral and is sent
only through `password_wo` / `service_password_wo`, with `password_version` / `service_password_version` as the
non-secret companions. State written by v1 under plain `password` / `service_password` is cleared by the
upgrade apply (see design, Migration). Option IDs resolved from names are data sources (not stored as managed
resources).

## Impact

- Files: `versions.tf`, `variables.tf`, `data.tf`, `locals.tf`, `main.tf`, `outputs.tf`, `checks.tf` (deleted),
  `tests/main.tftest.hcl`, `examples/minimal`, `examples/complete`, `README.md` (upgrade section, usage tables;
  generated block via terraform-docs), `SECURITY.md`, `openspec/config.yaml` context line (`~> 2.86`).
- Specs: `module-contract`, `servers`, `ssh-keys`, `flexible-ips` (deltas in this change).
- Tests: mock-provider runs for each new validation; the mock cannot plan a server (non-computed `offer_id` /
  `os_id`), so server-bearing behaviour is verified on a throwaway copy, as in the archived changes.
- Standards: `terraform-versioning`, `terraform-providers`, `terraform-security`, `terraform-variables`,
  `terraform-outputs`, `terraform-testing`, `quality-simplicity`, `quality-security`,
  `quality-production-readiness`.
