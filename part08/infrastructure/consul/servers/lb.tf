resource "azurerm_lb" "private" {
  name                = "lb-private-consul-servers"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location

  frontend_ip_configuration {
    name      = "private"
    subnet_id = azurerm_subnet.default.id
  }
}

resource "azurerm_lb_backend_address_pool" "private" {
  name            = "private-consul-servers"
  loadbalancer_id = azurerm_lb.private.id
}

resource "azurerm_lb_probe" "private" {
  loadbalancer_id = azurerm_lb.private.id
  name            = "status"
  protocol        = "Tcp"
  port            = 8501
}

resource "azurerm_lb_rule" "private_dns" {
  name                           = "private-dns"
  loadbalancer_id                = azurerm_lb.private.id
  protocol                       = "Udp"
  frontend_port                  = 53
  backend_port                   = 8600
  frontend_ip_configuration_name = azurerm_lb.private.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.private.id

  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.private.id,
  ]
}

resource "azurerm_lb_rule" "http" {
  name                           = "http-api"
  loadbalancer_id                = azurerm_lb.private.id
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 8501
  frontend_ip_configuration_name = azurerm_lb.private.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.private.id

  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.private.id,
  ]
}
