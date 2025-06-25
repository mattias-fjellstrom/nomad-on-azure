resource "azurerm_resource_group" "default" {
  name     = "rg-nomad-on-azure"
  location = var.azure_location

  tags = {
    projet = "nomad"
  }
}
