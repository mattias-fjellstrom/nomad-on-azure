data "azuread_client_config" "current" {}

resource "azuread_application" "boundary" {
  display_name = "boundary-host-discovery"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "boundary" {
  client_id = azuread_application.boundary.client_id
  owners    = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "boundary" {
  service_principal_id = azuread_service_principal.boundary.id
}

resource "azurerm_role_assignment" "reader" {
  principal_id         = azuread_service_principal.boundary.object_id
  role_definition_name = "Reader"
  scope                = "/subscriptions/${var.azure_subscription_id}"
}
