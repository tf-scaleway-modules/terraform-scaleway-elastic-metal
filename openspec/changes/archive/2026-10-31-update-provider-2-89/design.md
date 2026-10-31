## Context

Flat module, `scaleway/scaleway ~> 2.86`, `required_version >= 1.11.0` (both unchanged). Provider 2.86.0 →
2.89.0 did not touch `scaleway_baremetal_server`, `scaleway_flexible_ip` or `scaleway_iam_ssh_key` (identical
docs, `server.go` differs only in its JSON import). Every argument adopted below is present in the 2.86.0
schema, so `versions.tf` stays as is. Server attributes flow `variables.tf` → `local.expanded_servers` →
`scaleway_baremetal_server.this`.

## Goals / Non-Goals

**Goals:** expose the missing server arguments with provider-equivalent defaults so existing consumers see no diff; fix the
output that cannot work.

**Non-Goals:** new resources, new lookups, a provider floor bump, behavioural changes to existing inputs.

## Decisions

Resources and arguments (introducing version = first provider version with it; all ≤ 2.86.0, hence no floor change):

| Argument | Resource | Provider schema | Module input |
|----------|----------|-----------------|--------------|
| `protected` | `scaleway_baremetal_server` | Optional bool, default `false`, in 2.86.0 | `optional(bool, false)` |
| `cloud_init` | `scaleway_baremetal_server` | Optional + Computed string, ≤ 127998 chars, in 2.86.0 | `optional(string)` (null) |
| `partitioning` | `scaleway_baremetal_server` | Optional string (JSON), in 2.86.0 | `optional(string)` (null) |
| `private_network.ipam_ip_ids` | `scaleway_baremetal_server` | Optional + Computed list, in 2.86.0 | `optional(list(string))` (null) |
| `private_network.vlan` (read) | `scaleway_baremetal_server` | Computed int, in 2.86.0 | output fix |
| `private_ips[*].address` (read) | `scaleway_baremetal_server` | Computed list, in 2.86.0 | new output |

The "introduced in" release was confirmed by their presence in the 2.86.0 docs and source; the exact earlier
release is irrelevant because the floor is already 2.86.

1. **Floor stays `~> 2.86`.** Decided by policy: raised only when an adopted argument needs it. None does. A raise
   would be MAJOR (`terraform-versioning`, `terraform-providers`) for no benefit.
2. **`server_private_ips` fix.** The `private_network` set exposes `vlan`; `vlan_id` is not an attribute, so the
   `for pn in server.private_network : pn.vlan_id` expression fails with "Unsupported attribute" as soon as a
   server exists (the mock suite cannot plan a server, so it was never caught). Change to `pn.vlan`. Output name,
   type and documented meaning (VLAN ID per attachment) are unchanged. Alternative of renaming the output was rejected:
   it would break the contract (`terraform-outputs` stable shapes).
3. **`server_private_ip_addresses`** is `{ for name, server in scaleway_baremetal_server.this : name => [for ip in server.private_ips : ip.address] }`,
   placed right after `server_private_ips` to follow resource order. A new output name avoids changing the shape of
   `server_private_ips` (alternative: repurpose it, rejected as breaking).
4. **Defaults follow `terraform-variables` ("no invented defaults").** `protected` defaults to `false`, which is
   the provider default; `cloud_init`, `partitioning` and `ipam_ip_ids` default to `null`. For `cloud_init` and
   `ipam_ip_ids` the provider marks the argument Computed, so a `null` config never produces a diff against
   the value the API reports. `locals.tf` passes the values through without `coalesce` (it would skip empty
   strings, see `fix-validation-and-state-docs`); `ipam_ip_ids` is passed as `private_network.value.ipam_ip_ids`, never as `[]`.
5. **Validations** (message names accepted values, one rejected-input test each):
   - `cloud_init`: `length(v) <= 127998` when non-null.
   - `partitioning`: `can(jsondecode(v))` when non-null. Schema contents are left to the API.
   - `ipam_ip_ids`: each entry matches `^([a-z]{2}-[a-z]{3}(-[0-9])?/)?[0-9a-f]{8}-…-[0-9a-f]{12}$`, the UUID or `<locality>/<uuid>` forms the provider accepts.
   All are written with `v == null || …` inside `alltrue([...])` over `var.servers`, like the existing validations.
6. **Secrets.** `cloud_init` has no write-only counterpart in 2.86–2.89 and stays in state. Following
   `terraform-security` ("when a secret unavoidably lands in state, SECURITY.md lists it"), add a row to the
   table. `servers` cannot be `sensitive` (it drives `for_each`). The existing `plain_installation_passwords`
   check is not extended.
7. **Tests.** Validations are tested with `expect_failures = [var.servers]` under the mock provider. Valid-input
   and output runs need a server and the baremetal data sources lack computed `offer_id`/`os_id` in the mock
   schema; tasks first try per-instance `override_data` for those lookups and otherwise follow the precedent of
   a throwaway-copy check, stated in the task result. Stubbing is limited to the data sources, never the server resource.

## Risks / Trade-offs

- [`protected = true` blocks `tofu destroy` of the server] → description says so; default stays `false`.
- [`partitioning` and `cloud_init` do not reinstall] The provider only reinstalls on `os`, `ssh_key_ids`,
  credentials and `reinstall_on_config_changes`; a `partitioning` edit alone is not applied to an installed server
  and `cloud_init` needs a reboot → README and variable description state this; no module logic added.
- [`cloud_init` support depends on the offer] → left to the API error at apply; a plan-time rule cannot know it.
- [`ipam_ip_ids` Optional+Computed: removing the attribute later keeps the assigned IPs] → expected provider behaviour, noted in the description.
- [Fix in item 2 changes an output that used to error] → only affects configurations that could not plan with a private network; patch-level.

## Migration Plan

Existing state: all new inputs are `null` / `false`, matching the stored values (`protected = false`, `cloud_init`
and `ipam_ip_ids` computed), so the second plan is empty and no `moved` block or state surgery is needed. Setting
`protected`, `cloud_init` or `ipam_ip_ids` later is an in-place update; `partitioning` is only honoured on install
or reinstall (set it at creation, or with `reinstall_on_config_changes = true` / `os` change). No resource is
replaced. Rollback: remove the attributes from `servers` (and, for `protected`, set it back to `false` first);
`ipam_ip_ids` already assigned remain on the server. Consumers keep their `?ref=` tag until they choose to upgrade.

## Implementation notes

- `range(127999)` is capped at 1024 values, so the too-long `cloud_init` test uses `format("%0127999d", 0)` (127999 characters).
- `override_data` cannot plan a server: it refuses the non-computed `offer_id` / `os_id` ("Non-computed field is not allowed to be overridden") and does not accept per-instance targets (`...this["web"]`). Accepted-input and output runs were therefore verified on a throwaway copy with both lookups replaced by literals (and the SSH key `id` overridden to a UUID); the in-repo suite only keeps the rejected-input runs and says so in its header comment.
