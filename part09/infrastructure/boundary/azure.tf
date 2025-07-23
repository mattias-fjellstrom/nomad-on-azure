resource "azurerm_resource_group" "default" {
  name     = "rg-boundary-on-azure"
  location = var.azure_location
}

data "azurerm_virtual_network" "default" {
  name                = "vnet-shared-platform"
  resource_group_name = "rg-shared-platform"
}

data "azurerm_nat_gateway" "default" {
  name                = "natgw-shared-platform"
  resource_group_name = "rg-shared-platform"
}

resource "azurerm_subnet_nat_gateway_association" "default" {
  subnet_id      = azurerm_subnet.egress_workers.id
  nat_gateway_id = data.azurerm_nat_gateway.default.id
}

#---------------------------------------------------------------------------------------------------
# INGRESS WORKER
#---------------------------------------------------------------------------------------------------
resource "azurerm_subnet" "ingress_workers" {
  name                 = "snet-boundary-ingress-workers"
  resource_group_name  = data.azurerm_virtual_network.default.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.default.name
  address_prefixes = [
    cidrsubnet(data.azurerm_virtual_network.default.address_space[0], 8, 100)
  ]
}

resource "azurerm_network_security_group" "ingress_workers" {
  name                = "nsg-boundary-ingress-workers"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_subnet_network_security_group_association" "ingress_workers" {
  subnet_id                 = azurerm_subnet.ingress_workers.id
  network_security_group_id = azurerm_network_security_group.ingress_workers.id
}

resource "azurerm_network_security_rule" "boundary_ssh" {
  name                        = "allow_ssh"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.default.name
  network_security_group_name = azurerm_network_security_group.ingress_workers.name
}

resource "azurerm_network_security_rule" "boundary_connect" {
  name                        = "allow_boundary_inbound"
  priority                    = 1010
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "9202"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.default.name
  network_security_group_name = azurerm_network_security_group.ingress_workers.name
}

#---------------------------------------------------------------------------------------------------
# EGRESS WORKER
#---------------------------------------------------------------------------------------------------
resource "azurerm_subnet" "egress_workers" {
  name                 = "snet-boundary-egress-workers"
  resource_group_name  = data.azurerm_virtual_network.default.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.default.name
  address_prefixes = [
    cidrsubnet(data.azurerm_virtual_network.default.address_space[0], 8, 110)
  ]
}

resource "azurerm_network_security_group" "egress_workers" {
  name                = "nsg-boundary-egress-workers"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_subnet_network_security_group_association" "egress_workers" {
  subnet_id                 = azurerm_subnet.egress_workers.id
  network_security_group_id = azurerm_network_security_group.egress_workers.id
}
