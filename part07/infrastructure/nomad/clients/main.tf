data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "default" {
  name     = "rg-nomad-clients-on-azure"
  location = var.azure_location

  tags = {
    projet = "nomad"
  }
}
