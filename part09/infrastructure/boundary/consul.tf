resource "boundary_host_set_plugin" "consul" {
  name            = "consul-host-set"
  host_catalog_id = boundary_host_catalog_plugin.azure.id
  attributes_json = jsonencode({
    "filter" = "tagName eq 'consul' and tagValue eq 'server'"
  })
}

resource "boundary_credential_ssh_private_key" "consul" {
  name                = "consul-ssh-key"
  credential_store_id = boundary_credential_store_static.azure.id
  username            = "azureuser"
  private_key         = file("../consul/servers/ssh_keys/servers.pem")
}

resource "boundary_target" "consul_ssh" {
  name        = "consul-servers-ssh"
  description = "Consul servers on Azure"
  scope_id    = boundary_scope.project.id

  type         = "ssh"
  default_port = "22"

  ingress_worker_filter = "\"ingress\" in \"/tags/type\""
  egress_worker_filter  = "\"egress\" in \"/tags/type\""

  host_source_ids = [
    boundary_host_set_plugin.consul.id,
  ]

  injected_application_credential_source_ids = [
    boundary_credential_ssh_private_key.consul.id,
  ]
}

resource "boundary_alias_target" "consul_ssh" {
  name           = "consul-servers-ssh"
  scope_id       = "global"
  value          = "consul.server"
  destination_id = boundary_target.consul_ssh.id
}

resource "boundary_host_static" "consul_http" {
  name            = "Consul UI"
  address         = "10.0.10.4"
  host_catalog_id = boundary_host_catalog_static.web.id
}

resource "boundary_host_set_static" "consul_http" {
  host_catalog_id = boundary_host_catalog_static.web.id
  host_ids = [
    boundary_host_static.consul_http.id,
  ]
}

resource "boundary_target" "consul_http" {
  name        = "consul-servers-http"
  description = "Consul servers UI on Azure"
  scope_id    = boundary_scope.project.id

  type         = "tcp"
  default_port = "443"

  ingress_worker_filter = "\"azure\" in \"/tags/type\""
  egress_worker_filter  = "\"azure\" in \"/tags/type\""

  host_source_ids = [
    boundary_host_set_static.consul_http.id,
  ]
}

resource "boundary_alias_target" "consul_http" {
  name                      = "consul-servers-http"
  scope_id                  = "global"
  value                     = "consul.${var.domain}"
  destination_id            = boundary_target.consul_http.id
  authorize_session_host_id = boundary_host_static.consul_http.id
}
