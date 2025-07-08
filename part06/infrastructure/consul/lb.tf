resource "azurerm_public_ip" "lb" {
  name                = "pip-consul-servers-lb"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "servers" {
  name                = "lb-consul-servers"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "servers" {
  name            = "consul-servers"
  loadbalancer_id = azurerm_lb.servers.id
}

resource "azurerm_lb_probe" "servers" {
  loadbalancer_id = azurerm_lb.servers.id
  name            = "status"
  protocol        = "Tcp"
  port            = 8500
}

resource "azurerm_lb_rule" "default" {
  name                           = "default"
  loadbalancer_id                = azurerm_lb.servers.id
  protocol                       = "Tcp"
  frontend_port                  = 8500
  backend_port                   = 8500
  frontend_ip_configuration_name = azurerm_lb.servers.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.servers.id
  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.servers.id,
  ]
}

resource "azurerm_lb_nat_rule" "ssh" {
  name                           = "ssh"
  resource_group_name            = azurerm_resource_group.default.name
  loadbalancer_id                = azurerm_lb.servers.id
  protocol                       = "Tcp"
  frontend_port_start            = 2222
  frontend_port_end              = 2224
  backend_port                   = 22
  frontend_ip_configuration_name = azurerm_lb.servers.frontend_ip_configuration[0].name
  backend_address_pool_id        = azurerm_lb_backend_address_pool.servers.id
}
