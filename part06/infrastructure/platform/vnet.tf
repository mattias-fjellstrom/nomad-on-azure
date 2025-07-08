resource "azurerm_virtual_network" "default" {
  name = "vnet-shared-platform"

  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name

  address_space = [
    var.vnet_cidr_range,
  ]
}
