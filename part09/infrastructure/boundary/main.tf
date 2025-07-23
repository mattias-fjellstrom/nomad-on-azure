resource "boundary_host_catalog_static" "web" {
  name     = "Azure Static Catalog"
  scope_id = boundary_scope.project.id
}

resource "boundary_host_catalog_plugin" "azure" {
  name        = "Azure Plugin Catalog"
  scope_id    = boundary_scope.project.id
  plugin_name = "azure"

  # the attributes below must be generated in azure by creating an ad application
  attributes_json = jsonencode({
    "disable_credential_rotation" = true,
    "tenant_id"                   = "${data.azuread_client_config.current.tenant_id}",
    "subscription_id"             = "${var.azure_subscription_id}",
    "client_id"                   = "${azuread_service_principal.boundary.client_id}",
  })

  secrets_json = jsonencode({
    "secret_value" = "${azuread_service_principal_password.boundary.value}"
  })
}

resource "boundary_credential_store_static" "azure" {
  name     = "azure-credential-store"
  scope_id = boundary_scope.project.id
}
