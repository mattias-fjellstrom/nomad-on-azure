resource "azurerm_virtual_network" "default" {
  name                = "vnet-nomad"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  address_space = [
    "10.0.0.0/16",
  ]
}

resource "azurerm_subnet" "nomad" {
  name                 = "snet-nomad"
  resource_group_name  = azurerm_resource_group.default.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes = [
    "10.0.10.0/24",
  ]
}

resource "azurerm_subnet" "consul" {
  name                 = "snet-consul"
  resource_group_name  = azurerm_resource_group.default.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes = [
    "10.0.20.0/24",
  ]
}
