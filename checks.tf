#--------------------------------------------------------------
# Plain installation passwords
# password and service_password are stored in state; the *_wo forms are not
#--------------------------------------------------------------

check "plain_installation_passwords" {
  assert {
    condition = alltrue([
      for k, v in var.servers : v.password == null && v.service_password == null
    ])
    error_message = "Servers [${join(", ", [for k, v in var.servers : k if v.password != null || v.service_password != null])}] set 'password' or 'service_password', which are stored in state. Use 'password_wo' / 'service_password_wo' with their '_version' companion instead (see SECURITY.md)."
  }
}
