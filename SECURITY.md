# Security

## What lands in state

| Value | Input | In state | Mitigation |
|-------|-------|:--------:|------------|
| Cloud-init user data | `servers.<key>.cloud_init` | yes, clear text | The provider has no write-only form; do not embed secrets, fetch them at boot (vault, instance metadata) |
| Installation and service passwords | `server_passwords.<key>` | no | Sensitive and ephemeral input sent through `password_wo` / `service_password_wo`; change `password_version` / `service_password_version` to apply a new value |
| SSH public keys | `ssh_keys.<key>.public_key` | yes | Public material, not a secret |

The `servers` input is not marked `sensitive`: it is iterated with `for_each`, which
rejects sensitive values; passwords therefore live in the separate ephemeral
`server_passwords` input. The `servers` and `ssh_keys` outputs are sensitive.

Supply passwords through `TF_VAR_*` environment variables, CI secrets or a vault, never in a
committed `*.tfvars` file, and keep the state in an encrypted backend with restricted access.

## Permissions

The module needs no IAM policy beyond managing Elastic Metal servers, flexible IPs and IAM
SSH keys in the target project, and reading offers, options and OS images.
