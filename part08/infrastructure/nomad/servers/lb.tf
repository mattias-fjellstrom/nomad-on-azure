resource "azurerm_lb" "nomad_servers" {
  name                = "lb-nomad-servers"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location

  frontend_ip_configuration {
    name      = "private"
    subnet_id = azurerm_subnet.default.id
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
  frontend_port                  = 443
  backend_port                   = 4646
  frontend_ip_configuration_name = azurerm_lb.nomad_servers.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.nomad_servers.id
  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.nomad_servers.id,
  ]
}
