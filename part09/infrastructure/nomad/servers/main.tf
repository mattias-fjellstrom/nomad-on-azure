data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "default" {
  name     = "rg-nomad-servers-on-azure"
  location = var.azure_location
}

resource "random_bytes" "nomad_gossip_key" {
  length = 32
}
