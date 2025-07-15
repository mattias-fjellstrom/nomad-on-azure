resource "azurerm_public_ip" "nomad_servers_lb" {
  name                = "pip-nomad-servers-lb"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "nomad_servers" {
  name                = "lb-nomad-servers"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.nomad_servers_lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "nomad_servers" {
  name            = "nomad-servers"
  loadbalancer_id = azurerm_lb.nomad_servers.id
}

resource "azurerm_lb_probe" "nomad_servers" {
  loadbalancer_id = azurerm_lb.nomad_servers.id
  name            = "nomad-status"
  protocol        = "Tcp"
  port            = 4646
}

resource "azurerm_lb_rule" "default" {
  name                           = "default"
  loadbalancer_id                = azurerm_lb.nomad_servers.id
  protocol                       = "Tcp"
  frontend_port                  = 4646
  backend_port                   = 4646
  frontend_ip_configuration_name = azurerm_lb.nomad_servers.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.nomad_servers.id
  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.nomad_servers.id,
  ]
}

resource "azurerm_lb_nat_rule" "ssh" {
  name                           = "ssh"
  resource_group_name            = azurerm_resource_group.default.name
  loadbalancer_id                = azurerm_lb.nomad_servers.id
  protocol                       = "Tcp"
  frontend_port_start            = 2222
  frontend_port_end              = 2224
  backend_port                   = 22
  frontend_ip_configuration_name = azurerm_lb.nomad_servers.frontend_ip_configuration[0].name
  backend_address_pool_id        = azurerm_lb_backend_address_pool.nomad_servers.id
}
