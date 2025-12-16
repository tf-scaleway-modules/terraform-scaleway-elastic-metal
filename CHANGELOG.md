# Changelog

All notable changes to this project will be documented in this file.

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

