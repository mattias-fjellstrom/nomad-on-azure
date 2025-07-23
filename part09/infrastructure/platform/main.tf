data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "default" {
  name     = "rg-shared-platform"
  location = var.azure_location
}
