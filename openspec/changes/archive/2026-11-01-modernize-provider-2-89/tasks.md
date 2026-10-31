# Tasks

Run every tool through `mise exec --` from the module root. Move any local `.terraform.lock.hcl` aside before
`pre-commit run -a` (terraform-docs would print the locked version instead of the constraint) and delete
`.terraform*` produced by `tofu init` afterwards.

## 1. Provider floor and project/location inputs

- [x] 1.1 `versions.tf`: `scaleway ~> 2.89`; `required_version` stays `>= 1.11.0`. Verify with `tofu init -backend=false && tofu validate`.
- [x] 1.2 `variables.tf`: remove `organization_id` and `project_name`; add `project_id` (`string`, default `null`, UUID validation "project_id must be a valid UUID."); `zone` default `null` with validation `var.zone == null || can(regex(...))`. Delete `data.scaleway_account_project` and the `project_id` output. Verify rejected-input runs for `project_id = "default"` and `zone = "paris"` in `tests/main.tftest.hcl` (`expect_failures`) and `tofu test`.
- [x] 1.3 `main.tf`: SSH keys, servers and flexible IPs use `var.project_id`; servers and flexible IPs use `var.zone`; lookups in `data.tf` use `var.zone`. Verify `tofu validate` and that the happy-path run plans one SSH key with no project data source.

## 2. Tags and SSH key inputs

- [x] 2.1 Rename `default_tags` to `tags` and `default_ssh_key_ids` to `ssh_key_ids` (variables, locals, precondition message "At least one SSH key must be provided via 'ssh_key_ids', per-server 'ssh_key_ids', or 'ssh_keys'."). Verify with a rejected-input run for `ssh_key_ids = ["abc"]` and `tofu test`.

## 3. Locals simplification

- [x] 3.1 Merge `expanded_servers` and `servers` into one `local.servers` holding `config`; drop every `coalesce` on `optional(type, default)` attributes (locals, `data.tf`, validations); keep `<server>-fip-<index>` keys and merge `var.tags` once. Verify with `tofu validate`, `tofu test`, and a throwaway-copy plan (offer and OS lookups replaced by literals) whose addresses equal the v1.3.0 plan.
- [x] 3.2 `main.tf`: read `each.value.config.<attribute>` directly. Verify the throwaway-copy plan shows no diff against the pre-change plan for a `count = 3` server with a flexible IP.

## 4. Ephemeral installation passwords

- [ ] 4.1 `variables.tf`: remove `password`, `password_wo`, `service_password`, `service_password_wo`, rename `*_wo_version` to `password_version` / `service_password_version`; add `server_passwords` (`sensitive = true`, `ephemeral = true`, default `{}`, description states that a new value needs a version bump). `main.tf` sends `try(var.server_passwords[each.value.base_name].password, null)` to `password_wo` and the service one likewise. Delete `checks.tf`. Verify `tofu validate`, and on the throwaway copy that the plan shows the password neither in output nor in state (`tofu show` / `tofu state pull` contain no password). Status: code and `tofu validate` done; the "no password in state" check needs an apply, which the mock-provider plan cannot show (write-only values are null in a plan), so it stays open for the real-account group.
- [x] 4.2 `SECURITY.md`: update the "what lands in state" table (plain password rows removed, `server_passwords` row: ephemeral, not in state; `cloud_init` row kept). Verify the table lists every secret-bearing input.

## 5. Options by name, flexible IP reverse, outputs

- [ ] 5.1 Options: `servers[*].options` becomes `map(object({ expires_at = optional(string) }))`; add `data.scaleway_baremetal_option.this` over the distinct option names; the `options` block sends the resolved ID. Verify on the throwaway copy that two servers sharing a name produce one lookup, and `tofu validate`. Status: implemented and validated; the throwaway-copy check of one lookup for a shared name was not run (the copy replaced the lookups with literals), so it stays open.
- [x] 5.2 Flexible IPs: add the `reverse` validation (message "reverse must be a fully qualified hostname such as api.example.com."). Verify with a rejected-input run (`reverse = "not a host"`) and an accepted `api.example.com` on the throwaway copy.
- [ ] 5.3 Outputs: remove `project_id`; rename `server_private_ips` to `server_vlan_ids` and `server_private_ip_addresses` to `server_private_ips`, descriptions updated. Verify with the throwaway copy: a server with a private network yields a VLAN list and an address list, and `tofu validate` passes. Status: outputs renamed and validated; the VLAN/address content check needs a real or recorded server, so it stays open.

## 6. Examples and documentation

- [x] 6.1 `examples/minimal`: drop `organization_id`/`project_name`, use `ssh_key_ids`. `examples/complete`: `project_id`, `zone`, `tags`, `ssh_key_ids`, options by name, `server_passwords` from an ephemeral variable, `password_version`, `reverse`, private network with `ipam_ip_ids`. Verify `tofu init -backend=false && tofu validate` in both.
- [x] 6.2 `README.md` outside the terraform-docs block: server attribute tables (options map, password versions), a new "Upgrading from v1 to v2" section listing every breaking change of the proposal with its consumer edit, and the compatibility matrix (provider `~> 2.89`). Update the `openspec/config.yaml` context lines that name `~> 2.86` and the plain passwords. Verify each upgrade row matches a breaking-change row of proposal.md.

## 7. Verification (local, no account)

- [x] 7.1 Run `tofu fmt -recursive`, `tofu init -backend=false && tofu validate`, `tflint --recursive`, `tofu test`, `pre-commit run -a` (lock file moved aside); report the output as-is, then delete `.terraform*`.
- [ ] 7.2 On the throwaway copy confirm that applying the same configuration twice yields an empty second plan (mock or recorded plan) and that no resource address changed. Status: not run; needs an apply (mock plan only), so it stays open for the real-account group (8.1).
- [x] 7.3 `mise exec -- openspec validate modernize-provider-2-89 --strict` and `--all --strict`.
- [x] 7.4 Commit subject (becomes the CHANGELOG line; `.cliff.toml` prints the message as-is): `Send installation passwords write-only, select options by name and replace the project lookup with project_id` with a body starting `BREAKING:` listing the renamed and removed inputs and outputs.

## 8. Real-account checks (requires a Scaleway account, run only on request)

- [ ] 8.1 Upgrade a v1.3.0 stack (server with plain `password`, a flexible IP, a private network) to the new version with `project_id` and `zone` set: confirm no replacement and, after apply, an empty second plan.
- [ ] 8.2 Confirm the provider behaviour when `server_passwords` is set without `password_version`, and that `password_version` bump applies a new password.
- [ ] 8.3 Confirm option names accepted by `data.scaleway_baremetal_option` for the options used in production (for example the Private Network option) and that reverse DNS `api.example.com` is accepted and read back unchanged.

## Workflow follow-up

- Archive the change after review, then release v2.0.0 (signed tag) and regenerate `CHANGELOG.md` with `mise run changelog`.
