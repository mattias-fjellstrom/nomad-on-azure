resource "azurerm_private_dns_resolver" "default" {
  name                = "default"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  virtual_network_id  = azurerm_virtual_network.default.id
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "default" {
  name                    = "default"
  location                = azurerm_resource_group.default.location
  private_dns_resolver_id = azurerm_private_dns_resolver.default.id

  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = azurerm_subnet.inbound.id
  }
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "default" {
  name                    = "default"
  location                = azurerm_resource_group.default.location
  subnet_id               = azurerm_subnet.outbound.id
  private_dns_resolver_id = azurerm_private_dns_resolver.default.id
}

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "default" {
  name                = "default"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  private_dns_resolver_outbound_endpoint_ids = [
    azurerm_private_dns_resolver_outbound_endpoint.default.id
  ]
}

resource "azurerm_private_dns_resolver_virtual_network_link" "default" {
  name                      = "default"
  virtual_network_id        = azurerm_virtual_network.default.id
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.default.id
}
