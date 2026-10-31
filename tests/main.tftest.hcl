# Runs that plan a server cannot use the mock provider: the offer_id and os_id
# attributes of the baremetal data sources are not computed in the provider schema,
# so a mock cannot supply them and main.tf cannot split the OS ID. The
# plain_installation_passwords check and flexible_ip_addresses are therefore
# not covered by this unit suite. override_data cannot fill the gap: it refuses
# non-computed fields (offer_id, os_id) and does not accept per-instance targets.
# The accepted values of protected, cloud_init, partitioning and ipam_ip_ids and
# the server_private_ips / server_private_ip_addresses outputs were checked on a
# throwaway copy with the two lookups replaced by literals; only the validations
# are tested here.

mock_provider "scaleway" {
  override_data {
    target = data.scaleway_account_project.this
    values = {
      id = "11111111-1111-1111-1111-111111111111"
    }
  }
}

variables {
  organization_id = "00000000-0000-0000-0000-000000000000"
  ssh_keys = {
    admin = { public_key = "ssh-ed25519 AAAA test@example.com" }
  }
}

run "happy_path" {
  command = plan

  variables {
    timeouts = { create = "2h", delete = "1h30m", update = "0" }
  }

  assert {
    condition     = length(scaleway_baremetal_server.this) == 0 && length(scaleway_iam_ssh_key.this) == 1
    error_message = "Expected one SSH key and no server"
  }
}

run "server_key_single_dash_rejected" {
  command = plan

  variables {
    servers = { "-" = { offer = "EM-A610R-NVME", os = "Ubuntu" } }
  }

  expect_failures = [var.servers]
}

run "server_key_single_underscore_rejected" {
  command = plan

  variables {
    servers = { "_" = { offer = "EM-A610R-NVME", os = "Ubuntu" } }
  }

  expect_failures = [var.servers]
}

run "server_key_trailing_hyphen_rejected" {
  command = plan

  variables {
    servers = { "web-" = { offer = "EM-A610R-NVME", os = "Ubuntu" } }
  }

  expect_failures = [var.servers]
}

run "timeout_malformed_rejected" {
  command = plan

  variables {
    timeouts = { create = "2 hours" }
  }

  expect_failures = [var.timeouts]
}

run "timeout_without_unit_rejected" {
  command = plan

  variables {
    timeouts = { delete = "30" }
  }

  expect_failures = [var.timeouts]
}

run "cloud_init_too_long_rejected" {
  command = plan

  variables {
    servers = {
      web = {
        offer      = "EM-A610R-NVME"
        os         = "Ubuntu"
        cloud_init = format("%0127999d", 0)
      }
    }
  }

  expect_failures = [var.servers]
}

run "partitioning_not_json_rejected" {
  command = plan

  variables {
    servers = {
      web = {
        offer        = "EM-A610R-NVME"
        os           = "Ubuntu"
        partitioning = "disks: []"
      }
    }
  }

  expect_failures = [var.servers]
}

run "ipam_ip_ids_not_uuid_rejected" {
  command = plan

  variables {
    servers = {
      web = {
        offer            = "EM-A610R-NVME"
        os               = "Ubuntu"
        private_networks = [{ id = "pn-id", ipam_ip_ids = ["not-a-uuid"] }]
      }
    }
  }

  expect_failures = [var.servers]
}
