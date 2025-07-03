locals {
  vnet_cidr_range = "10.0.0.0/16"

  subnets = {
    consul_servers = {
      name = "snet-consul-servers"
      cidr = cidrsubnet(local.vnet_cidr_range, 8, 0)
    }

    nomad_servers = {
      name = "snet-nomad-servers"
      cidr = cidrsubnet(local.vnet_cidr_range, 8, 2)
    }

    nomad_clients = {
      name = "snet-nomad-clients"
      cidr = cidrsubnet(local.vnet_cidr_range, 8, 3)
    }
  }
}

resource "azurerm_virtual_network" "default" {
  name                = "vnet-nomad"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  address_space = [
    local.vnet_cidr_range,
  ]
}

resource "azurerm_subnet" "all" {
  for_each             = local.subnets
  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.default.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = [each.value.cidr]
}
