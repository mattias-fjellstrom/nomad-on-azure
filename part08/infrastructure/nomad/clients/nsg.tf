resource "azurerm_network_security_group" "nomad_clients" {
  name                = "nsg-nomad-clients"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_subnet_network_security_group_association" "nomad_clients" {
  subnet_id                 = azurerm_subnet.default.id
  network_security_group_id = azurerm_network_security_group.nomad_clients.id
}
