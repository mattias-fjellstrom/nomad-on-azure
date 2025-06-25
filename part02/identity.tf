data "azuread_client_config" "current" {}

data "azurerm_client_config" "current" {}

# resource "azuread_application" "servers" {
#   display_name = "nomad-servers"
# }

# resource "azuread_service_principal" "servers" {
#   client_id = azuread_application.servers.client_id
# }

# resource "azuread_service_principal_password" "servers" {
#   service_principal_id = azuread_service_principal.servers.id
#   display_name         = "Nomad Servers"
# }

# resource "azurerm_role_assignment" "reader" {
#   scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
#   principal_id         = azuread_service_principal.servers.object_id
#   role_definition_name = "Reader"
# }
