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

data "azurerm_nat_gateway" "default" {
  name                = "natgw-shared-platform"
  resource_group_name = "rg-shared-platform"
}

resource "azurerm_subnet_nat_gateway_association" "default" {
  subnet_id      = azurerm_subnet.default.id
  nat_gateway_id = data.azurerm_nat_gateway.default.id
}
