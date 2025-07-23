resource "azurerm_subnet" "appgw" {
  name                 = "snet-appgw"
  virtual_network_name = azurerm_virtual_network.default.name
  resource_group_name  = azurerm_resource_group.default.name
  address_prefixes = [
    cidrsubnet(var.vnet_cidr_range, 8, 55),
  ]
}

resource "azurerm_network_security_group" "appgw" {
  name                = "nsg-appgw"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_subnet_network_security_group_association" "appgw" {
  subnet_id                 = azurerm_subnet.appgw.id
  network_security_group_id = azurerm_network_security_group.appgw.id

  depends_on = [
    azurerm_network_security_rule.appgw_gateway_manager,
  ]
}

resource "azurerm_network_security_rule" "appgw_http" {
  name                        = "allow_http"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.default.name
  network_security_group_name = azurerm_network_security_group.appgw.name
}

resource "azurerm_network_security_rule" "appgw_gateway_manager" {
  name                        = "allow_gw_manager"
  priority                    = 1100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["65200-65535"]
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.default.name
  network_security_group_name = azurerm_network_security_group.appgw.name
}

resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  allocation_method   = "Static"
}

data "azurerm_dns_zone" "public" {
  name                = var.public_dns_zone_name
  resource_group_name = var.public_dns_zone_resource_group
}

resource "azurerm_dns_a_record" "appgw" {
  name                = "appgw"
  resource_group_name = data.azurerm_dns_zone.public.resource_group_name
  zone_name           = data.azurerm_dns_zone.public.name
  ttl                 = 60
  records = [
    azurerm_public_ip.appgw.ip_address,
  ]
}

resource "azurerm_application_gateway" "default" {
  name                = "appgw-nomad"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "primary"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "primary"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name  = "nginx"
    fqdns = ["nginx.service.consul"]
  }

  backend_http_settings {
    name                  = "default"
    protocol              = "Http"
    port                  = 8080
    cookie_based_affinity = "Disabled"
  }

  http_listener {
    name                           = "default"
    frontend_ip_configuration_name = "primary"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "nginx"
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = "default"
    backend_address_pool_name  = "nginx"
    backend_http_settings_name = "default"
  }
}
