#---------------------------------------------------------------------------------------------------
# PUBLIC
#---------------------------------------------------------------------------------------------------
resource "azurerm_public_ip" "lb" {
  name                = "pip-consul-servers-lb"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "public" {
  name                = "lb-public-consul-servers"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "public" {
  name            = "public-consul-servers"
  loadbalancer_id = azurerm_lb.public.id
}

resource "azurerm_lb_probe" "public" {
  loadbalancer_id = azurerm_lb.public.id
  name            = "status"
  protocol        = "Tcp"
  port            = 8501
}

resource "azurerm_lb_rule" "public" {
  name                           = "public"
  loadbalancer_id                = azurerm_lb.public.id
  protocol                       = "Tcp"
  frontend_port                  = 8501
  backend_port                   = 8501
  frontend_ip_configuration_name = azurerm_lb.public.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.public.id
  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.public.id,
  ]
}

resource "azurerm_lb_nat_rule" "ssh" {
  name                           = "ssh"
  resource_group_name            = azurerm_resource_group.default.name
  loadbalancer_id                = azurerm_lb.public.id
  protocol                       = "Tcp"
  frontend_port_start            = 2222
  frontend_port_end              = 2224
  backend_port                   = 22
  frontend_ip_configuration_name = azurerm_lb.public.frontend_ip_configuration[0].name
  backend_address_pool_id        = azurerm_lb_backend_address_pool.public.id
}

#---------------------------------------------------------------------------------------------------
# PRIVATE
#---------------------------------------------------------------------------------------------------
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
