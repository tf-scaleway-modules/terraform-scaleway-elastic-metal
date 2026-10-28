## ADDED Requirements

### Requirement: SSH keys created from a map
The module SHALL create one `scaleway_iam_ssh_key` per entry of `ssh_keys`, named after the map key, with the entry's `public_key` and `disabled` (optional, default `false`), in the resolved project.

#### Scenario: Two keys declared
- **WHEN** `ssh_keys = { admin = { public_key = "ssh-ed25519 AAAA..." }, ci = { public_key = "ssh-rsa AAAA...", disabled = true } }`
- **THEN** two SSH keys named `admin` (enabled) and `ci` (disabled) are planned and `ssh_key_ids` has the keys `admin` and `ci`

#### Scenario: No keys declared
- **WHEN** `ssh_keys` is `{}`
- **THEN** no SSH key resource is planned

### Requirement: SSH public key format is validated
Every `public_key` in `ssh_keys` MUST start with one of `ssh-rsa`, `ssh-ed25519`, `ecdsa-sha2-nistp256`, `ecdsa-sha2-nistp384`, `ecdsa-sha2-nistp521`, `sk-ssh-ed25519@openssh.com` or `sk-ecdsa-sha2-nistp256@openssh.com` followed by whitespace.

#### Scenario: Unsupported key type
- **WHEN** a `public_key` is `"ssh-dss AAAA..."`
- **THEN** the plan fails with "All public keys must be valid SSH public keys (ssh-rsa, ssh-ed25519, or ecdsa)."

#### Scenario: Key without a body
- **WHEN** a `public_key` is `"ssh-ed25519"` with nothing after it
- **THEN** the plan fails with the same error

### Requirement: Created keys are attached to every server
Every server SHALL receive the IDs of all SSH keys created by the module, merged with the IDs from `default_ssh_key_ids` and the server's own `ssh_key_ids`, without duplicates. The servers SHALL depend on the created SSH keys.

#### Scenario: Created and existing keys merged
- **WHEN** `ssh_keys` declares `admin`, `default_ssh_key_ids` holds one UUID and a server sets `ssh_key_ids` with another UUID
- **THEN** that server's `ssh_key_ids` contains the created `admin` key ID and both UUIDs, each once

### Requirement: At least one SSH key per server
Every server MUST have at least one SSH key source: a non-empty merge of `default_ssh_key_ids` and the server's `ssh_key_ids`, or a non-empty `ssh_keys`. Otherwise the server's creation SHALL fail with a precondition error.

#### Scenario: No SSH key anywhere
- **WHEN** a server is declared, `ssh_keys = {}`, `default_ssh_key_ids = []` and the server has no `ssh_key_ids`
- **THEN** the plan fails with "At least one SSH key must be provided via 'default_ssh_key_ids', per-server 'ssh_key_ids', or 'ssh_keys'."

#### Scenario: Only a created key
- **WHEN** a server is declared, `ssh_keys` has one entry and no existing key IDs are given
- **THEN** the precondition is satisfied
