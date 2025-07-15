data "azurerm_virtual_network" "default" {
  name                = "vnet-shared-platform"
  resource_group_name = "rg-shared-platform"
}

resource "azurerm_subnet" "default" {
  name                 = "snet-nomad-clients"
  resource_group_name  = data.azurerm_virtual_network.default.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.default.name
  address_prefixes = [
    cidrsubnet(data.azurerm_virtual_network.default.address_space[0], 8, 30)
  ]
}
