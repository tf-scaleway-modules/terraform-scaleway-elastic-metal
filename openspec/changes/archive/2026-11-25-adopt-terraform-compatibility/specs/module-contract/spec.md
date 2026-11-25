## MODIFIED Requirements

### Requirement: Supported tooling and providers
The module SHALL require OpenTofu/Terraform `>= 1.11.0` and the `scaleway/scaleway` provider `~> 2.89`, and SHALL declare no other provider. Both OpenTofu and Terraform SHALL accept the module at that floor; the single `required_version` constraint serves both and no OpenTofu-only construct is used.

#### Scenario: Version constraints
- **WHEN** a consumer runs `tofu init` with a version older than 1.11.0
- **THEN** initialization fails on the `required_version` constraint

#### Scenario: Provider floor
- **WHEN** a consumer pins the `scaleway` provider to 2.88.0
- **THEN** initialization fails on the provider constraint

#### Scenario: Terraform consumer
- **WHEN** the module and each example under `examples/` are initialised with `terraform init -backend=false` and checked with `terraform validate` on Terraform 1.11.0 or later
- **THEN** validation succeeds, exactly as with OpenTofu
