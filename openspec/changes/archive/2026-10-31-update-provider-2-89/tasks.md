## 1. Inputs and wiring

- [x] 1.1 `variables.tf`: add `protected = optional(bool, false)`, `cloud_init = optional(string)`, `partitioning = optional(string)` to `servers` and `ipam_ip_ids = optional(list(string))` to `private_networks`; add the three validations from design.md decision 5 with the messages of the delta specs. Verify: `tofu validate` passes, `tofu fmt -check -recursive` is clean
- [x] 1.2 `locals.tf`: pass `protected`, `cloud_init`, `partitioning` through `expanded_servers` (no `coalesce` on strings; `protected` is already non-null from its default). Verify: `tofu validate`
- [x] 1.3 `main.tf`: set `protected`, `cloud_init`, `partitioning` on `scaleway_baremetal_server.this` and `ipam_ip_ids` in the `private_network` dynamic block (not `[]` when unset). Verify: `tofu validate`; second plan of an existing configuration is empty (not run: no credentials; all new inputs default to the stored values)
- [x] 1.4 `versions.tf`: leave `~> 2.86` unchanged. Verify: `git diff versions.tf` is empty

## 2. Outputs

- [x] 2.1 `outputs.tf`: change `pn.vlan_id` to `pn.vlan` in `server_private_ips`; add `server_private_ip_addresses` (description, after `server_private_ips`). Verify: `tofu validate`, tflint `terraform_documented_outputs` clean

## 3. Tests

- [x] 3.1 `tests/main.tftest.hcl`: one run per new validation with a rejected value and `expect_failures = [var.servers]` (`cloud_init` of 127999 chars via `format("%0127999d", 0)`, as `range` is capped at 1024 values, `partitioning = "disks: []"`, `ipam_ip_ids = ["not-a-uuid"]`). Verify: `tofu test` shows each run passing
- [x] 3.2 Add accepted-input runs (`partitioning = jsonencode({...})`, `ipam_ip_ids` with and without locality prefix) and output runs for `server_private_ips` / `server_private_ip_addresses`, using `override_data` for `data.scaleway_baremetal_offer.this[...]` and `data.scaleway_baremetal_os.this[...]` only. If the mock still cannot plan a server, say so in the header comment of the test file (as for the existing check run) and verify on a throwaway copy with the lookups stubbed; report which was done. Verify: `tofu test` (done: `override_data` refuses `offer_id`/`os_id` and per-instance targets, so the accepted-input and output runs passed on a throwaway copy with the lookups stubbed; the in-repo suite keeps the rejected-input runs and says so in its header)
- [x] 3.3 There is no `tests/integration` fixture in this repo; do not create one here. Report that no real-server apply was run (Do not run anything against a real Scaleway account unless asked)

## 4. Examples and docs

- [x] 4.1 `examples/complete/main.tf`: show `protected`, `cloud_init = file(...)`/inline cloud-config without secrets, `partitioning = jsonencode(...)` and `ipam_ip_ids` in the commented single-server and database blocks; add `server_private_ip_addresses` to `examples/complete/outputs.tf`. Verify: `tofu init -backend=false && tofu validate` in `examples/complete` and `examples/minimal`
- [x] 4.2 `SECURITY.md`: add `cloud_init` to the "what lands in state" table (in state, clear text; mitigation: do not embed secrets, fetch them at boot). Verify: row present, wording matches the existing table
- [x] 4.3 README: usage note for the four inputs (reinstall/reboot caveats, `protected` blocks destroy); no upgrade note needed, this is not a breaking change. The generated tables come from terraform-docs. Verify: reviewed in the diff after step 5.2

## 5. Verification and commit

- [x] 5.1 Run `tofu fmt -recursive`, `tofu init -backend=false && tofu validate`, `tflint --recursive` and `tofu test`; none may fail. Report the output as-is
- [x] 5.2 Pitfall: a local `.terraform.lock.hcl` makes terraform-docs write the locked provider version instead of the `~> 2.86` constraint into the README. Move the lock file (root and examples) aside before `pre-commit run -a` and before pushing, then run `pre-commit run -a` and check the README provider/requirement rows still read `~> 2.86`
- [x] 5.3 Commit subject (reads as the CHANGELOG line, git-cliff generates `CHANGELOG.md`, never edit it by hand): "Add protected, cloud_init, partitioning and IPAM IPs to servers; fix server_private_ips output". Verify: `git log -1 --format=%s`
- [x] 5.4 `mise run spec-validate` passes with the change in place

## Workflow follow-up

- On archive: main specs `servers` and `module-contract` change (no requirement removed); the release is a **minor** bump and the provider floor is unchanged.
