resource "azurerm_resource_group" "default" {
  name     = "rg-consul-on-azure"
  location = var.azure_location

  tags = {
    projet = "nomad"
  }
}
