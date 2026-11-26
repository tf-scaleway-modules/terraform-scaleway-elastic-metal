# Changelog

All notable changes to this project will be documented in this file.


## [2.0.1] - 2026-11-25
- Validate the module with Terraform and pin both toolchains
- Rewrite input and output descriptions as single-line prose so they render on the Terraform Registry
## [2.0.0] - 2026-11-01
- Send installation passwords write-only, select options by name and replace the project lookup with project_id

BREAKING: v2.0.0; provider ~> 2.89.

- organization_id and project_name are removed: pass project_id; zone
  defaults to the provider zone (set zone = "fr-par-2" to keep servers).
- default_tags becomes tags, default_ssh_key_ids becomes ssh_key_ids.
- servers[*].password, password_wo, service_password and
  service_password_wo are removed: passwords come from the sensitive,
  ephemeral server_passwords input and never reach state;
  password_wo_version/service_password_wo_version become
  password_version/service_password_version. Set
  reinstall_on_config_changes = false for the upgrade apply.
- servers[*].options is a map keyed by option name (looked up once per
  name).
- Output project_id is removed; server_private_ips becomes server_vlan_ids
  and server_private_ip_addresses becomes server_private_ips.
- Flexible IP reverse must be a fully qualified hostname.

See "Upgrading from v1 to v2" in the README.
## [1.3.0] - 2026-10-31
- Add protected, cloud_init, partitioning and IPAM IPs to servers; fix server_private_ips output
## [1.2.2] - 2026-10-28
- Fix server key and timeouts validation and flexible IP outputs; warn on plain passwords

- Single-character server keys must now be alphanumeric.
- timeouts values must be durations such as 30m or 1h30m.
- flexible_ip_addresses no longer mixes the flexible IPs of web and web-fip-x.
- A server without a description no longer fails to plan.
- A check warns when password or service_password is used, because they land in state; password_wo and service_password_wo do not.
- Add SECURITY.md and unit tests; the server_private_ips description now says it holds VLAN IDs.
No upgrade action needed.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
## [1.2.1] - 2026-10-28
- Key the pre-commit cache on mise.toml and .pre-commit-config.yaml

The cache was keyed on the branch, so a branch kept tools installed by the previous mise, which the new one no longer puts on PATH (tofu not found). Keying it on the files that define the toolchain, as in scaleway-compute and scaleway-storage, starts a fresh cache whenever the toolchain changes and shares it across branches and tags.
- Install mise 2026.10.17 in CI to avoid the GitHub API rate limit

The pre-commit job installed an old mise that resolves every tool through api.github.com without a token, and failed with 403 rate-limit errors on the shared office runner whenever its cache was cold (new refs such as merge requests and tags). mise 2026.9.14 and later resolve releases through mise-versions.jdx.dev.
- Run validate:specs in merge request pipelines

A job without rules: only runs in branch and tag pipelines, so the merge request pipeline did not validate openspec/. rules: when: always matches the other validate jobs.
- Adopt OpenSpec and publish the baseline specs

Planning adopts OpenSpec, aligned with the other leminnov Terraform
modules: the engineering standards come from the quality, repository and
terraform OpenSpec stores. openspec/config.yaml follows the terraform-module profile
(stores pinned at quality v1.2.6, repository v4.1.0, terraform v1.2.6) and
AGENTS.md, imported by CLAUDE.md, routes to them. openspec/specs/ holds the
baseline specification of the module as released, produced by the archived
adopt-openspec change. The openspec-* skills are installed for Claude Code
and OpenCode, openspec 1.14.3 and node are pinned in mise.toml with the
spec-validate and spec-setup tasks, and the validate:specs CI job runs
openspec validate --all --strict. The module contract is unchanged.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
## [1.2.0] - 2026-10-14
- feat: add write-only installation passwords and upgrade scaleway provider to ~> 2.86

- servers: add password_wo/service_password_wo (+ *_wo_version), never
  stored in the state.
- Require OpenTofu/Terraform >= 1.11 (write-only arguments).
- Bump the scaleway provider constraint to ~> 2.86 (module and examples).

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
## [1.1.0] - 2025-12-25
- Updates example with placeholder values
- Adds Elastic Metal module initial version

Introduces a complete refactor of the Elastic Metal module, enabling the creation and management of bare metal servers and flexible IPs on Scaleway.

It replaces the previous configuration with a more robust and flexible approach.
- Updates documentation and Scaleway provider version

Updates the Scaleway provider version constraint in the README
to allow versions greater than 2.64.

Adds documentation for the `count` parameter for servers,
allowing the creation of multiple identical servers.

Adds `os_images` to outputs.
## [1.0.0] - 2025-12-16
- Enhances security and input validation

Adds a precondition to require at least one SSH key for server
creation, enhancing security by preventing accidental unauthenticated
access.

Implements validation for SSH key IDs to ensure they are valid UUIDs,
preventing errors and improving the robustness of the configuration.

Marks server and SSH key outputs as sensitive to prevent unintended
disclosure of sensitive information.
- Adds support for server count parameter

Introduces the `count` parameter to allow creating multiple identical servers with a single server definition.

This simplifies the configuration and management of multiple servers with similar specifications.
- Enables server count and flexible IPs

Allows the creation of multiple identical servers using a 'count' parameter in the server definition.

Improves flexible IP handling by correctly associating them with expanded server instances.

Optimizes data lookups by performing them on base server definitions, avoiding redundant lookups for multiple server instances.
- Adds trailing dot to reverse DNS entries

Adds a trailing dot to the reverse DNS entries for the flexible IPs.

This ensures that the reverse DNS records are properly interpreted as fully qualified domain names (FQDNs), which is a best practice for DNS configuration.
- Updates example and adds baremetal offer lists

Updates the example configuration for web-02 to reflect updated hardware and OS options.

Adds mise tasks to list available baremetal offers in different zones. This aids in discovery and configuration of baremetal resources.
- Adds private network and option attachments

Extends server configuration to support attaching
private networks and server options.

Documents the configuration options for private
networks and server options.

Updates example with the new configuration options.
- Updates example and adds dependency

Updates the example configuration to use a different zone.

Adds a `depends_on` clause to the `scaleway_baremetal_server`
resource to ensure SSH keys are created before the server.

Provides a warning regarding SSH key generation in example.
- Updates examples and documentation for OS versions

Updates the example configurations and documentation to reflect the latest available OS versions for Elastic Metal servers.
Also updates the main module to retrieve the OS ID correctly.
Adds scaleway-cli to mise.toml for development.
- Adds OS version to Elastic Metal server configuration

Enables specifying the operating system version for Elastic Metal servers.

This change introduces the `os_version` attribute to the `servers` map, allowing users to select a specific version of the operating system during server creation.

It also updates the documentation and examples to reflect the new attribute.
- Adds subscription period to server config

Adds the ability to specify a subscription period (hourly/monthly) for
Elastic Metal servers in the server configuration.

This allows users to choose the billing model for their servers
directly within the module.
- Adds subscription period to baremetal offers

Allows users to specify a subscription period (hourly or monthly) for baremetal servers.

This change introduces a `subscription_period` attribute to the `servers` variable, providing more flexibility in billing options.
Adds validation to ensure the subscription period is either "hourly" or "monthly".
- Refactors project ID handling

Updates the module to use `organization_id` and `project_name`
instead of `project_id` for project identification.

This change improves project management and aligns with Scaleway's
current best practices for project identification. It also introduces
a data source to fetch the project ID based on the name and
organization ID.
- Improves code readability with section headers

Enhances the clarity and organization of the Terraform code by introducing descriptive section headers.
These headers delineate logical blocks within each file, improving overall readability and maintainability.
- Removes unused local variable

Removes the `default_ssh_key_ids` local variable as it is no longer being used.
This simplifies the code and avoids potential confusion.
- Adds initial version of the module README

Creates the initial README file for the Scaleway Elastic Metal Terraform module.

Provides a high-level overview of the module's purpose, features,
usage examples, server configuration details, and licensing information.
- Adds SSH key creation and attachment

Enables the creation of new SSH keys via the module, which are then attached to the bare metal servers.

This commit introduces the ability to either reference existing SSH keys by ID or create new SSH keys, providing flexibility in how SSH access is managed.

It also fixes an issue by renaming `ssh_key_ids` to `existing_ssh_key_ids` in locals to reflect that those are pre-existing keys and making the new SSH key resource ID's available on the baremetal server creation resource.
- WIP Refactors module for Elastic Metal server deployment

This commit introduces a complete refactor of the Elastic Metal module, enabling the creation and management of bare metal servers and flexible IPs on Scaleway.

It replaces the previous configuration with a more robust and flexible approach.
The changes include:

- Adds support for defining server configurations, including offer, OS, hostname, description, tags, and SSH keys.
- Implements dynamic Flexible IP assignment to servers.
- Uses data sources to resolve offer and OS IDs.
- Introduces variables for project ID, default SSH keys, default tags, and timeouts.
- Creates outputs for server IDs, IPs, offer details, and flexible IPs.
- Initial commit
