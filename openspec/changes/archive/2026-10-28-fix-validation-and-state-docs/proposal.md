## Why

Writing the `adopt-openspec` baseline surfaced six suspected defects, and writing the unit tests a seventh. Each was verified
against the code; six are fixed here, one is left as intended. Nothing is breaking.

## What Changes

| # | Issue | Decision | Breaking |
|---|-------|----------|----------|
| 1 | Plain `password` / `service_password` land in state, nothing says so | Add a `check` block warning when either is set, add `SECURITY.md` with a "what lands in state" table, point the README at it. The `servers` input stays non-sensitive (it is iterated by `for_each`, so `sensitive` is impossible) and the plain attributes stay (removing them is breaking). | No |
| 2 | `server_private_ips` description says "private network IPs" but returns each attachment's `vlan_id` | Description-only fix; the value is the published contract and changing it is breaking | No |
| 3 | Server-key validation accepts any single character (`-`, `_`) | Code fix: single character must be alphanumeric. Only rejects keys that yield an invalid hostname | No (fix) |
| 4 | `flexible_ip_addresses` prefix match picks up flexible IPs of server `web-fip-x` for server `web` | Code fix: match on the `server_name` already held in `local.flexible_ips` | No (fix) |
| 5 | `timeouts` unvalidated, malformed duration fails at apply | Add a validation requiring Go duration syntax (what the provider parses); only rejects values that already failed at apply | No (fix) |
| 7 | Found by the new tests: `coalesce(config.description, "")` in `locals.tf` errors on the default empty description (`coalesce` skips empty strings), so any server without a `description` failed to plan | Code fix: use `config.description` (the attribute already defaults to `""`) | No (fix) |
| 6 | SSH-key precondition lives on the server resource, runs only when a server exists | Left: the rule is per server ("every server MUST have a key"), so with no server there is nothing to enforce; moving it would add a rule, not fix one | n/a |

Semver: **patch** (fixes, validation of already-failing input, documentation, a warning
`check`). Per `terraform-versioning`, no input or output is removed or retyped.

State: `password` and `service_password` land in state in clear text when used (issue 1);
the `*_wo` forms never do. Documented in `SECURITY.md`. No new secret-bearing input.

Standards applied: `terraform-security` (guardrails via `check`, what lands in state),
`terraform-versioning`, `terraform-testing`, `terraform-variables`, `terraform-outputs`.

## Capabilities

### Modified Capabilities
- `servers`: key validation tightened, warning check for plain passwords
- `module-contract`: `timeouts` validation, `server_private_ips` description
- `flexible-ips`: `flexible_ip_addresses` matches by owning server

## Impact

`variables.tf`, `outputs.tf`, new `checks.tf`, new `SECURITY.md` and `tests/main.tftest.hcl`,
README, `examples/complete`. No state migration, no address change.
