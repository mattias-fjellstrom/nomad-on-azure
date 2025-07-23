resource "azurerm_virtual_network" "default" {
  name = "vnet-shared-platform"

  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name

  address_space = [
    var.vnet_cidr_range,
  ]
}

resource "azurerm_subnet" "inbound" {
  name                 = "snet-inbound"
  virtual_network_name = azurerm_virtual_network.default.name
  resource_group_name  = azurerm_resource_group.default.name
  address_prefixes = [
    cidrsubnet(var.vnet_cidr_range, 12, 0),
  ]

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}

resource "azurerm_subnet" "outbound" {
  name                 = "snet-outbound"
  virtual_network_name = azurerm_virtual_network.default.name
  resource_group_name  = azurerm_resource_group.default.name
  address_prefixes = [
    cidrsubnet(var.vnet_cidr_range, 12, 1),
  ]

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}

resource "azurerm_network_security_group" "dns" {
  name                = "nsg-dns-resolvers"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_subnet_network_security_group_association" "inbound" {
  subnet_id                 = azurerm_subnet.inbound.id
  network_security_group_id = azurerm_network_security_group.dns.id
}

resource "azurerm_subnet_network_security_group_association" "outbound" {
  subnet_id                 = azurerm_subnet.outbound.id
  network_security_group_id = azurerm_network_security_group.dns.id
}
