resource "azurerm_resource_group" "default" {
  name     = "rg-shared-platform"
  location = var.azure_location
}
