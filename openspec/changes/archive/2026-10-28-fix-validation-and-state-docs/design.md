## Context

Flat module, `scaleway/scaleway ~> 2.86`, `required_version >= 1.11.0` (unchanged).

## Decisions

- **Plain passwords (1)**: `servers` is the `for_each` collection of `data.scaleway_baremetal_*`
  and keys of `local.servers`; a `sensitive` value cannot drive `for_each`, and `ephemeral`
  inputs cannot reach non-write-only arguments, so neither is applied. Dropping the plain
  attributes would be major and `*_wo` already exists as the secure path. Chosen: a
  `check "plain_installation_passwords"` in `checks.tf` listing the server keys that set
  `password` or `service_password` (never the values), plus `SECURITY.md`. A `check` only
  warns, so existing configurations keep planning.
- **Private IPs output (2)**: the provider's `private_network` block exposes `vlan_id`;
  the output keeps returning it and only its description changes.
- **Server key (3)**: regex becomes `^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9])$`,
  dropping the `|| length(k) == 1` escape.
- **Flexible IP addresses (4)**: filter with `local.flexible_ips[key].server_name == name`;
  same keys as `scaleway_flexible_ip.this`, no extra data.
- **Timeouts (5)**: each of `create`, `update`, `delete` must match
  `^(0|([0-9]+(\.[0-9]+)?(ns|us|µs|ms|s|m|h))+)$`, the Go duration syntax used by the
  provider's timeouts.
- **Empty description (7)**: `description` is `optional(string, "")`, so `locals.tf` uses it directly instead of `coalesce(..., "")`, which raises on an all-empty argument list.
- **Precondition (6)**: unchanged.

## State and diff

No resource, argument value or address changes: no perpetual diff, no `moved` block, no
state migration.
