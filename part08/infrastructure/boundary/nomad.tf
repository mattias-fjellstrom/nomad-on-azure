#---------------------------------------------------------------------------------------------------
# NOMAD SERVERS
#---------------------------------------------------------------------------------------------------
resource "boundary_host_set_plugin" "nomad_servers" {
  name            = "nomad-servers-host-set"
  host_catalog_id = boundary_host_catalog_plugin.azure.id
  attributes_json = jsonencode({
    "filter" = "tagName eq 'nomad' and tagValue eq 'server'"
  })
}

resource "boundary_credential_ssh_private_key" "nomad_servers" {
  name                = "nomad-servers-ssh-key"
  credential_store_id = boundary_credential_store_static.azure.id
  username            = "azureuser"
  private_key         = file("../nomad/servers/ssh_keys/servers.pem")
}

resource "boundary_target" "nomad_servers_ssh" {
  name        = "nomad-servers-ssh"
  description = "Nomad servers on Azure"
  scope_id    = boundary_scope.project.id

  type         = "ssh"
  default_port = "22"

  ingress_worker_filter = "\"azure\" in \"/tags/type\""
  egress_worker_filter  = "\"azure\" in \"/tags/type\""

  host_source_ids = [
    boundary_host_set_plugin.nomad_servers.id,
  ]

  injected_application_credential_source_ids = [
    boundary_credential_ssh_private_key.nomad_servers.id,
  ]
}

resource "boundary_alias_target" "nomad_servers_ssh" {
  name           = "nomad-servers-ssh"
  scope_id       = "global"
  value          = "nomad.server"
  destination_id = boundary_target.nomad_servers_ssh.id
}

resource "boundary_host_static" "nomad_servers_http" {
  name            = "Nomad UI"
  address         = "10.0.20.4"
  host_catalog_id = boundary_host_catalog_static.web.id
}

resource "boundary_host_set_static" "nomad_servers_http" {
  host_catalog_id = boundary_host_catalog_static.web.id
  host_ids = [
    boundary_host_static.nomad_servers_http.id,
  ]
}

resource "boundary_target" "nomad_servers_http" {
  name        = "nomad-servers-http"
  description = "Nomad servers UI on Azure"
  scope_id    = boundary_scope.project.id

  type         = "tcp"
  default_port = "443"

  ingress_worker_filter = "\"ingress\" in \"/tags/type\""
  egress_worker_filter  = "\"egress\" in \"/tags/type\""

  host_source_ids = [
    boundary_host_set_static.nomad_servers_http.id,
  ]
}

resource "boundary_alias_target" "nomad_servers_http" {
  name                      = "nomad-servers-http"
  scope_id                  = "global"
  value                     = "nomad.${var.domain}"
  destination_id            = boundary_target.nomad_servers_http.id
  authorize_session_host_id = boundary_host_static.nomad_servers_http.id
}

#---------------------------------------------------------------------------------------------------
# NOMAD CLIENTS
#---------------------------------------------------------------------------------------------------
resource "boundary_host_set_plugin" "nomad_clients" {
  name            = "nomad-clients-host-set"
  host_catalog_id = boundary_host_catalog_plugin.azure.id
  attributes_json = jsonencode({
    "filter" = "tagName eq 'nomad' and tagValue eq 'client'"
  })
}

resource "boundary_credential_ssh_private_key" "nomad_clients" {
  name                = "nomad-clients-ssh-key"
  credential_store_id = boundary_credential_store_static.azure.id
  username            = "azureuser"
  private_key         = file("../nomad/clients/ssh_keys/servers.pem")
}

resource "boundary_target" "nomad_clients_ssh" {
  name        = "nomad-clients-ssh"
  description = "Nomad clients on Azure"
  scope_id    = boundary_scope.project.id

  type         = "ssh"
  default_port = "22"

  ingress_worker_filter = "\"ingress\" in \"/tags/type\""
  egress_worker_filter  = "\"egress\" in \"/tags/type\""

  host_source_ids = [
    boundary_host_set_plugin.nomad_clients.id,
  ]

  injected_application_credential_source_ids = [
    boundary_credential_ssh_private_key.nomad_clients.id,
  ]
}

resource "boundary_alias_target" "nomad_clients_ssh" {
  name           = "nomad-clients-ssh"
  scope_id       = "global"
  value          = "nomad.client"
  destination_id = boundary_target.nomad_clients_ssh.id
}
