## Why

The module pins `scaleway/scaleway ~> 2.86`, which already resolves to 2.89.0 (released 2026-10-27).
A diff of the provider docs and schema between 2.86.0 and 2.89.0 shows **no change to
`scaleway_baremetal_server`, `scaleway_flexible_ip` or `scaleway_iam_ssh_key`**; the only delta touching the
module is `data.scaleway_account_project` gaining a computed `srn` (2.87.0), which nothing consumes. The value
of this update is therefore a gap analysis: `scaleway_baremetal_server` arguments that exist since before
2.86 and that the module does not expose, plus one output that cannot work against the provider schema.

## What Changes

Adopted (all exist in provider 2.86.0, verified in the 2.86.0 docs and `internal/services/baremetal/server.go`):

| # | Item | Provider argument / attribute | Class |
|---|------|-------------------------------|-------|
| 1 | Fix `server_private_ips`: it reads `pn.vlan_id`, but the `private_network` block exposes `vlan` (no `vlan_id` in 2.86.0 or 2.89.0), so the output errors once a server is attached to a private network | `private_network.vlan` | fix |
| 2 | `servers[*].protected` (`optional(bool)`): guard a server against accidental deletion through the API | `protected` | new input |
| 3 | `servers[*].cloud_init` (`optional(string)`, max 127998 chars): cloud-init user data | `cloud_init` | new input |
| 4 | `servers[*].partitioning` (`optional(string)`, must be JSON): custom partitioning schema | `partitioning` | new input |
| 5 | `servers[*].private_networks[*].ipam_ip_ids` (`optional(list(string))`): pin the private IPs from IPAM | `private_network.ipam_ip_ids` | new input |
| 6 | New output `server_private_ip_addresses`: private IPv4/IPv6 addresses per server | `private_ips[*].address` | new output |

Semver: **minor**. Per `terraform-versioning`: new optional inputs with `null`/provider-equivalent defaults and a new
output are minor; the output fix is a patch. No input or output is removed, retyped or renamed, no default
changes, no address changes. **Provider floor stays `~> 2.86`**: nothing adopted needs an argument introduced
after 2.86.0, so raising it (a MAJOR bump under `terraform-versioning` and `terraform-providers`) is not
justified; consumers already resolve 2.89.0. Not breaking, so no README upgrade note is needed beyond the
documented new inputs.

Modified inputs / outputs: `servers` gains four optional attributes (types above, `null` default except
`protected = false`); `server_private_ips` keeps its type and meaning (VLAN ID per attachment) but now works;
`server_private_ip_addresses` is new. No existing input or output changes type, default or meaning.

State: `cloud_init` lands in state in clear text when set (user data can embed secrets) and `partitioning` is
non-secret. `cloud_init` has no write-only form in the provider, so `terraform-security` is applied by
documenting it in `SECURITY.md` ("what lands in state"); no `check` block is added because detecting secrets in
free text is unreliable. The README and `SECURITY.md` tell users to fetch secrets at boot instead of templating
them into user data. No other secret-bearing input is added.
`protected`, `partitioning` and `ipam_ip_ids` carry no secret.

Considered and deferred / rejected:

- Raise the floor to `~> 2.89`: no adopted item needs it (see above).
- `data.scaleway_account_project.srn` (2.87.0): no consumer in the module; adding an output only for it fails the
  "do not output every attribute" rule of `terraform-outputs`.
- `data.scaleway_baremetal_option` to reference options by name instead of ID (exists before 2.86): adds a lookup per option and
  loosens `options.id` from required to optional, which widens the contract; IDs are already accepted. Revisit on demand.
- `scaleway_flexible_ip_mac_address`: separate resource with a virtual-MAC lifecycle (needs a server-side VMAC
  option), no ask yet.
- Outputs `domain`, `ipv4`/`ipv6` server attributes: already reachable through the sensitive `servers` output and
  `server_ips` / `server_ipv6s`; extra outputs would duplicate them.
- Making `servers` sensitive/ephemeral for `cloud_init`: impossible, `servers` keys drive `for_each` (same reason
  as in `fix-validation-and-state-docs`).
- Validation that the chosen offer supports cloud-init: only known by the API at apply time.

Standards applied: `terraform-versioning` (classification, floor), `terraform-providers` (floor rule, feature
flags: `null` default sends nothing), `terraform-variables` (`optional()` with `null` default, validation per
constraint), `terraform-outputs` (new output with description, grouping after server outputs),
`terraform-testing` (rejected-input run per validation), `terraform-security` (what lands in state),
`quality-simplicity` and `quality-production-readiness` (small scope, no invented defaults).

## Capabilities

### Modified Capabilities
- `servers`: new `protected`, `cloud_init`, `partitioning` attributes and `ipam_ip_ids` on private networks, with validations
- `module-contract`: new output `server_private_ip_addresses`, `server_private_ips` content corrected, outputs list updated

## Impact

`variables.tf`, `locals.tf`, `main.tf`, `outputs.tf`, `tests/main.tftest.hcl`, `examples/complete`,
`SECURITY.md`, README (generated tables and a short usage note). `versions.tf` is unchanged. State: existing
servers plan with no diff (see design); new attributes are in-place updates when set. No `moved` block.
