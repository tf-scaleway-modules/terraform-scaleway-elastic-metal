# Security

## What lands in state

| Value | Input | In state | Mitigation |
|-------|-------|:--------:|------------|
| Installation password | `servers.<key>.password` | yes, clear text | Use `password_wo` with `password_wo_version`; the module warns (`plain_installation_passwords` check) when the plain form is set |
| Service password | `servers.<key>.service_password` | yes, clear text | Use `service_password_wo` with `service_password_wo_version`; same warning |
| Write-only passwords | `password_wo`, `service_password_wo` | no | Sent through the provider's write-only arguments; change `*_wo_version` to apply a new value |
| SSH public keys | `ssh_keys.<key>.public_key` | yes | Public material, not a secret |

The `servers` input is not marked `sensitive`: it is iterated with `for_each`, which
rejects sensitive values. Plan output can therefore show the plain `password` and
`service_password` values; the `servers` and `ssh_keys` outputs are sensitive.

Supply passwords through `TF_VAR_*` environment variables, CI secrets or a vault, never in a
committed `*.tfvars` file, and keep the state in an encrypted backend with restricted access.

## Permissions

The module needs no IAM policy beyond managing Elastic Metal servers, flexible IPs and IAM
SSH keys in the target project, and reading the project, offers and OS images.
