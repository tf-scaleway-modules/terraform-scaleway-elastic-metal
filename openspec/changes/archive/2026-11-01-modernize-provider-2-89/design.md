# Design

## Context

Flat module at v1.3.0: `scaleway/scaleway ~> 2.86`, `required_version >= 1.11.0`. Server attributes flow
`variables.tf` to `local.expanded_servers` (copies every attribute) to `local.servers` (adds hostname,
description, tags, SSH key IDs) to `scaleway_baremetal_server.this`. The project comes from
`data.scaleway_account_project.this` (name + organization). See proposal.md for motivation and the full tables.
Schema checked: `/tmp/scw-schema/schema-2.89.0.json`; the three managed resources have no writable argument the
module lacks, so nothing here needs an argument newer than 2.86; the floor moves to `~> 2.89` by repository convention.

## Goals / Non-Goals

**Goals:** conventions of the Scaleway module family (`project_id`, `null` locations, `tags`, ephemeral secrets);
fewer lines in `locals.tf`; no secret in state from module-managed passwords; unchanged resource addresses.

**Non-Goals:** new resources, a `moved` block, changing flexible IP keys, reshaping `private_networks`, the
partition-schema data source.

## Decisions

Resources and arguments (provider version = first version carrying it; all are in 2.89.0 and none is newer than 2.86):

| Argument / data source | Use | Module input |
|------------------------|-----|--------------|
| `scaleway_baremetal_server.password_wo`, `service_password_wo`, `*_wo_version` | write-only passwords (needs OpenTofu/Terraform >= 1.11, already the floor) | `server_passwords` + `servers[*].password_version` / `service_password_version` |
| `data.scaleway_baremetal_option` (`name`, `zone`; computed `option_id`) | option name to ID | keys of `servers[*].options` |
| `scaleway_baremetal_server.options.id` / `expires_at` | attach option | `options[name].expires_at` |
| `scaleway_baremetal_server.project_id`, `scaleway_iam_ssh_key.project_id`, `scaleway_flexible_ip.project_id` (Optional + Computed) | project | `project_id` (`null` sends nothing) |
| `zone` on server, flexible IP, offer, OS and option lookups (Optional + Computed) | location | `zone` (`null` sends nothing) |
| `scaleway_flexible_ip.reverse` (Optional + Computed) | reverse DNS | `flexible_ips[*].reverse`, validated |
| `private_network.vlan`, `private_ips[*].address` (Computed) | outputs | `server_vlan_ids`, `server_private_ips` |

1. **`project_id` replaces the data source.** `null` passes `project_id = null`; the provider resolves its default
   project and the attribute is Computed, so there is no diff. Alternative: keep the lookup by name (rejected:
   needs `organization_id`, one extra API call, and a name that can be ambiguous). `organization_id` is dropped:
   nothing in the module is organization-scoped (SSH keys take `project_id`).
2. **`zone = null` default.** Same mechanism. Consumers relying on `fr-par-2` set it. Alternative: keep the
   default `fr-par-2` (rejected: contradicts the family convention and hides the provider zone). The validation
   becomes `var.zone == null || can(regex(...))`.
3. **`tags` input.** `distinct(concat(var.tags, config.tags))` for servers and flexible IPs. SSH keys have no tags in the schema.
4. **Ephemeral passwords.** `server_passwords` is `map(object({ password = optional(string), service_password =
   optional(string) }))`, `sensitive = true`, `ephemeral = true`, `default = {}`. The resource reads
   `try(var.server_passwords[each.value.base_name].password, null)` in `password_wo` (and `service_password_wo`
   likewise); ephemeral values are legal only in write-only arguments, which is exactly where they go. Keys are
   the `servers` keys, not expanded names, so a `count` group shares credentials (as before: attributes were
   per definition). Versions stay in `servers` (non-secret, they must be known to plan). Plain `password` /
   `service_password` are removed rather than deprecated: keeping a state-stored form beside a write-only one is
   the dual input the brief asks to remove, and the `check` becomes pointless. Alternatives: (a) ephemeral
   `servers` (rejected: keys drive `for_each`, ephemeral values cannot); (b) one ephemeral variable per
   secret (rejected: does not scale with servers). The provider requires `*_wo_version` to change for a new
   value; the variable descriptions say so. A precondition cannot read an ephemeral value, so a password without a
   version is not rejected at plan; the provider decides (real-account check below).
5. **Options by name.** `local.option_names = toset(flatten([for s in var.servers : keys(s.options)]))`, one
   `data.scaleway_baremetal_option.this[name]` per distinct name, `zone = var.zone`. `options` becomes a map keyed
   by name so duplicates are impossible and a reorder is not a change; the server's `dynamic "options"` iterates
   the map and sends `id = data.scaleway_baremetal_option.this[options.key].option_id`. The option's `name` is
   computed by the API and read back, `expires_at` is Optional + Computed: `null` never diffs. Alternative: keep
   `id` and add `name` (rejected: dual input). A wrong name fails at plan with the data source's own error, which
   is the desired early failure. The set order of `options` in the provider is a set, so no ordering diff.
6. **`private_networks` stays a list.** IDs are often unknown at plan (a VPC created in the same configuration), and
   unknown map keys would break `for_each`. `ipam_ip_ids` unchanged (Optional + Computed: never send `[]`).
7. **Locals collapse.** One `local.servers`:
   `{ for name, config in var.servers : ... for i in range(config.count) : key => { base_name, config, hostname,
   description, tags, ssh_key_ids } }`. `count`, `subscription_period`, `description`, `tags` and the other optional
   attributes carry defaults in the `variable`, so every `coalesce(x, default)` is removed (a `null` input already
   takes the default; `coalesce` of `""` would also skip an empty description, the bug fixed in
   `fix-validation-and-state-docs`). `main.tf` reads `each.value.config.<attribute>`. The `flexible_ips` local keeps the key
   `<server>-fip-<index>` and merges `var.tags` once.
8. **Outputs.** `project_id` is removed (no data source; with `null` the module does not know the project).
   `server_private_ips` (VLANs) becomes `server_vlan_ids`; `server_private_ip_addresses` becomes
   `server_private_ips`. Alternative: keep the names (rejected: `server_private_ips` returning VLAN IDs is the
   inconsistent name; the swap is listed as a breaking change with the consumer edit).
9. **Reverse DNS validation.** `reverse == null || can(regex("^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,63}\\.?$", reverse))`
   in a `servers` validation, one message. The provider reads the reverse back as given, so a trailing dot is
   not normalized by the module; unset stays `null` (Computed) and never diffs. Alternative: no validation
   (rejected: the API error appears only at apply, after the server exists).
10. **Floor.** `scaleway ~> 2.89`, `required_version >= 1.11.0` unchanged (write-only arguments and ephemeral
    variables need 1.11). Provider 2.90.0 becomes selectable once published; its only relevant item is the ephemeral
    `scaleway_iam_api_key.srn`, unused here.
11. **Tests.** `mock_provider "scaleway"` cannot plan a server (non-computed `offer_id`/`os_id`, `override_data`
    refuses them), so the suite keeps rejected-input runs (`project_id`, `zone`, `ssh_key_ids`, `reverse`, plus the
    existing ones) and the empty happy path; accepted values (options by name, passwords, outputs, tags merge)
    are verified on a throwaway copy with the offer and OS lookups replaced by literals, as in the archived
    changes, and the task says so.

## Risks / Trade-offs

- [Project or zone change replaces everything] → upgrade section: set `project_id` and `zone` explicitly before the first plan; the plan must show no replacement.
- [Password move triggers a reinstall when `reinstall_on_config_changes = true`] → upgrade with it set to `false`; the plain value leaves state through an in-place update.
- [Option name differs from the displayed name] → the data source fails at plan with the API's list; README shows `scw baremetal option list`.
- [`server_private_ips` now a different type] → documented; renaming both outputs is a deliberate major-release correction.
- [A password without its version] → cannot be rejected at plan (ephemeral); documented in the variable description, covered by the real-account check.
- [Flexible IP list reorder replaces IPs] → pre-existing; documented, key scheme deliberately unchanged.
- [Adding a created SSH key changes every server's `ssh_key_ids`, which the provider treats as a reinstall trigger when `reinstall_on_config_changes` is true] → pre-existing; noted in README.

## Migration Plan

Resource addresses are unchanged, so no `moved` block exists and none is possible for the removed data source
(data sources hold no state worth moving). Steps for a consumer on v1.3.0: (1) set `project_id` (ID of the project
`project_name` pointed to) and `zone`; (2) rename `default_tags`, `default_ssh_key_ids`; (3) convert `options` ids
to names; (4) move passwords to `server_passwords`, rename the version attributes, set
`reinstall_on_config_changes = false`; (5) rename the two outputs where used; (6) `tofu init -upgrade`,
`tofu plan`: expect only in-place updates for servers that stored plain passwords and no changes otherwise; apply;
(7) the next plan must be empty. Rollback: pin the previous tag; passwords written through write-only arguments are
not in state, so v1.3.0 `password_wo` plus the same version continues to work. Unchanged infrastructure: empty
second plan, confirmed by task 7.2.

## Open Questions

- Keep the `count` attribute? Kept here for address stability and the `-01` naming; removing it is a separate decision that would also change keys.
