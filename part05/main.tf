resource "azurerm_resource_group" "default" {
  name     = "rg-nomad-on-azure"
  location = var.azure_location

  tags = {
    projet = "nomad"
  }
}

resource "random_bytes" "nomad_gossip_key" {
  length = 32
}
