## 1. Code
- [x] 1.1 `variables.tf`: tighten the server key validation, add the `timeouts` validation
- [x] 1.2 `outputs.tf`: fix `server_private_ips` description, match flexible IPs by `server_name`
- [x] 1.3 `checks.tf`: add `plain_installation_passwords` check
- [x] 1.4 `locals.tf`: stop coalescing the empty default `description`
- [x] 1.5 `SECURITY.md` (what lands in state), README pointers and timeout format; `examples/complete` shows `password_wo`

## 2. Tests
- [x] 2.1 `tests/main.tftest.hcl`: happy path, rejected keys (`-`, `_`, trailing hyphen), rejected timeouts. The check and `flexible_ip_addresses` runs cannot use the mock provider (`offer_id` / `os_id` are not computed in the provider schema); they were verified on a throwaway copy with the lookups stubbed

## 3. Verification
- [x] 3.1 `tofu fmt -recursive`, `tofu validate`, `tflint --recursive`, `tofu test`, `pre-commit run -a`
- [x] 3.2 Commit subject: "Fix server key and timeouts validation, flexible IP outputs; warn on plain passwords"
